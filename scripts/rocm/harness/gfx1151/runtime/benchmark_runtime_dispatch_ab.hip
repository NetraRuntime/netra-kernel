// SPDX-License-Identifier: MIT
#include <hip/hip_runtime.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <dlfcn.h>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

using InitFn = int (*)();
using LinearFn = int (*)(void*, void*, void*, void*, unsigned, unsigned,
                         unsigned, void*);

struct Api {
  void* handle = nullptr;
  InitFn init = nullptr;
  LinearFn linear = nullptr;
  std::string path;
};

struct Stats {
  double median = 0.0;
  double p90 = 0.0;
  double mean = 0.0;
};

void hip_check(hipError_t status, const char* what) {
  if (status != hipSuccess) {
    throw std::runtime_error(std::string(what) + ": " +
                             hipGetErrorString(status));
  }
}

void netra_check(int status, const char* what) {
  if (status != 0) {
    throw std::runtime_error(std::string(what) + " returned " +
                             std::to_string(status));
  }
}

Api load_api(const char* path) {
  Api api;
  api.path = path;
  api.handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (!api.handle) {
    throw std::runtime_error(std::string("dlopen ") + path + ": " + dlerror());
  }
  api.init = reinterpret_cast<InitFn>(
      dlsym(api.handle, "netra_mxfp4_sgl_init"));
  api.linear = reinterpret_cast<LinearFn>(
      dlsym(api.handle, "netra_mxfp4_sgl_linear"));
  if (!api.init || !api.linear) {
    throw std::runtime_error(std::string("missing netra symbol in ") + path);
  }
  return api;
}

Stats summarize(std::vector<double> values) {
  if (values.empty()) return {};
  double sum = 0.0;
  for (double value : values) sum += value;
  std::sort(values.begin(), values.end());
  const auto percentile = [&](double fraction) {
    const double position = fraction * static_cast<double>(values.size() - 1);
    const size_t lower = static_cast<size_t>(position);
    const size_t upper = std::min(lower + 1, values.size() - 1);
    const double weight = position - static_cast<double>(lower);
    return values[lower] * (1.0 - weight) + values[upper] * weight;
  };
  return {percentile(0.5), percentile(0.9), sum / values.size()};
}

uint64_t fnv1a64(const std::vector<uint16_t>& values) {
  uint64_t hash = UINT64_C(1469598103934665603);
  const auto* bytes = reinterpret_cast<const uint8_t*>(values.data());
  for (size_t i = 0; i < values.size() * sizeof(uint16_t); ++i) {
    hash ^= bytes[i];
    hash *= UINT64_C(1099511628211);
  }
  return hash;
}

struct Capture {
  hipGraph_t graph = nullptr;
  hipGraphExec_t exec = nullptr;
  double capture_us = 0.0;
  double instantiate_us = 0.0;
  size_t node_count = 0;
};

Capture capture_linear(Api& api, hipStream_t stream, void* packed, void* scale,
                       void* activation, void* output, unsigned n,
                       unsigned k) {
  Capture result;
  const auto capture_start = std::chrono::steady_clock::now();
  hip_check(hipStreamBeginCapture(stream, hipStreamCaptureModeGlobal),
            "hipStreamBeginCapture");
  netra_check(api.linear(packed, scale, activation, output, 1, n, k,
                         reinterpret_cast<void*>(stream)),
              "captured netra_mxfp4_sgl_linear");
  hip_check(hipStreamEndCapture(stream, &result.graph), "hipStreamEndCapture");
  const auto capture_end = std::chrono::steady_clock::now();
  result.capture_us =
      std::chrono::duration<double, std::micro>(capture_end - capture_start).count();

  hip_check(hipGraphGetNodes(result.graph, nullptr, &result.node_count),
            "hipGraphGetNodes count");
  const auto instantiate_start = std::chrono::steady_clock::now();
  hip_check(hipGraphInstantiate(&result.exec, result.graph, nullptr, nullptr, 0),
            "hipGraphInstantiate");
  const auto instantiate_end = std::chrono::steady_clock::now();
  result.instantiate_us = std::chrono::duration<double, std::micro>(
                              instantiate_end - instantiate_start)
                              .count();
  return result;
}

void collect_eager_host(Api& old_api, Api& new_api, hipStream_t stream,
                        void* packed, void* scale, void* activation,
                        void* old_output, void* new_output, unsigned n,
                        unsigned k, size_t samples, std::vector<double>& old_us,
                        std::vector<double>& new_us) {
  auto one = [&](Api& api, void* output, std::vector<double>& times) {
    const auto start = std::chrono::steady_clock::now();
    const int status = api.linear(packed, scale, activation, output, 1, n, k,
                                  reinterpret_cast<void*>(stream));
    const auto stop = std::chrono::steady_clock::now();
    netra_check(status, "eager netra_mxfp4_sgl_linear");
    times.push_back(
        std::chrono::duration<double, std::micro>(stop - start).count());
  };

  old_us.reserve(samples);
  new_us.reserve(samples);
  for (size_t i = 0; i < samples; ++i) {
    if ((i & 1U) == 0) {
      one(old_api, old_output, old_us);
      one(new_api, new_output, new_us);
    } else {
      one(new_api, new_output, new_us);
      one(old_api, old_output, old_us);
    }
    if ((i + 1) % 32 == 0) hip_check(hipStreamSynchronize(stream), "eager sync");
  }
  hip_check(hipStreamSynchronize(stream), "final eager sync");
}

void collect_eager_gpu(Api& old_api, Api& new_api, hipStream_t stream,
                       void* packed, void* scale, void* activation,
                       void* old_output, void* new_output, unsigned n,
                       unsigned k, size_t samples, std::vector<double>& old_us,
                       std::vector<double>& new_us) {
  hipEvent_t start = nullptr;
  hipEvent_t stop = nullptr;
  hip_check(hipEventCreate(&start), "hipEventCreate start");
  hip_check(hipEventCreate(&stop), "hipEventCreate stop");
  auto one = [&](Api& api, void* output, std::vector<double>& times) {
    hip_check(hipEventRecord(start, stream), "hipEventRecord start");
    netra_check(api.linear(packed, scale, activation, output, 1, n, k,
                           reinterpret_cast<void*>(stream)),
                "event netra_mxfp4_sgl_linear");
    hip_check(hipEventRecord(stop, stream), "hipEventRecord stop");
    hip_check(hipEventSynchronize(stop), "hipEventSynchronize");
    float milliseconds = 0.0f;
    hip_check(hipEventElapsedTime(&milliseconds, start, stop),
              "hipEventElapsedTime");
    times.push_back(static_cast<double>(milliseconds) * 1000.0);
  };
  old_us.reserve(samples);
  new_us.reserve(samples);
  for (size_t i = 0; i < samples; ++i) {
    if ((i & 1U) == 0) {
      one(old_api, old_output, old_us);
      one(new_api, new_output, new_us);
    } else {
      one(new_api, new_output, new_us);
      one(old_api, old_output, old_us);
    }
  }
  hip_check(hipEventDestroy(start), "hipEventDestroy start");
  hip_check(hipEventDestroy(stop), "hipEventDestroy stop");
}

void collect_graph_host(Capture& old_capture, Capture& new_capture,
                        hipStream_t stream, size_t samples,
                        std::vector<double>& old_us,
                        std::vector<double>& new_us) {
  auto one = [&](Capture& capture, std::vector<double>& times) {
    const auto start = std::chrono::steady_clock::now();
    const hipError_t status = hipGraphLaunch(capture.exec, stream);
    const auto stop = std::chrono::steady_clock::now();
    hip_check(status, "hipGraphLaunch");
    times.push_back(
        std::chrono::duration<double, std::micro>(stop - start).count());
  };
  old_us.reserve(samples);
  new_us.reserve(samples);
  for (size_t i = 0; i < samples; ++i) {
    if ((i & 1U) == 0) {
      one(old_capture, old_us);
      one(new_capture, new_us);
    } else {
      one(new_capture, new_us);
      one(old_capture, old_us);
    }
    if ((i + 1) % 32 == 0) hip_check(hipStreamSynchronize(stream), "graph sync");
  }
  hip_check(hipStreamSynchronize(stream), "final graph sync");
}

void collect_graph_gpu(Capture& old_capture, Capture& new_capture,
                       hipStream_t stream, size_t samples,
                       std::vector<double>& old_us,
                       std::vector<double>& new_us) {
  hipEvent_t start = nullptr;
  hipEvent_t stop = nullptr;
  hip_check(hipEventCreate(&start), "hipEventCreate graph start");
  hip_check(hipEventCreate(&stop), "hipEventCreate graph stop");
  auto one = [&](Capture& capture, std::vector<double>& times) {
    hip_check(hipEventRecord(start, stream), "graph event start");
    hip_check(hipGraphLaunch(capture.exec, stream), "event hipGraphLaunch");
    hip_check(hipEventRecord(stop, stream), "graph event stop");
    hip_check(hipEventSynchronize(stop), "graph event synchronize");
    float milliseconds = 0.0f;
    hip_check(hipEventElapsedTime(&milliseconds, start, stop),
              "graph event elapsed");
    times.push_back(static_cast<double>(milliseconds) * 1000.0);
  };
  old_us.reserve(samples);
  new_us.reserve(samples);
  for (size_t i = 0; i < samples; ++i) {
    if ((i & 1U) == 0) {
      one(old_capture, old_us);
      one(new_capture, new_us);
    } else {
      one(new_capture, new_us);
      one(old_capture, old_us);
    }
  }
  hip_check(hipEventDestroy(start), "hipEventDestroy graph start");
  hip_check(hipEventDestroy(stop), "hipEventDestroy graph stop");
}

void print_stats(const char* name, const Stats& stats, bool comma) {
  std::cout << "    \"" << name << "\": {\"median_us\": " << stats.median
            << ", \"p90_us\": " << stats.p90 << ", \"mean_us\": "
            << stats.mean << "}" << (comma ? "," : "") << "\n";
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 3 || argc > 4) {
    std::cerr << "usage: " << argv[0]
              << " OLD_LIB NEW_LIB [host_samples]\n";
    return 2;
  }
  try {
    const size_t host_samples = argc == 4 ? std::stoul(argv[3]) : 10000;
    constexpr size_t event_samples = 201;
    constexpr unsigned n = 64;
    constexpr unsigned k = 2048;

    Api old_api = load_api(argv[1]);
    Api new_api = load_api(argv[2]);
    netra_check(old_api.init(), "old init");
    netra_check(new_api.init(), "new init");

    int device = -1;
    hipDeviceProp_t properties{};
    hip_check(hipGetDevice(&device), "hipGetDevice");
    hip_check(hipGetDeviceProperties(&properties, device),
              "hipGetDeviceProperties");

    std::vector<uint8_t> host_packed(static_cast<size_t>(n) * k / 2);
    std::vector<uint8_t> host_scale(static_cast<size_t>(n) * k / 32, 127);
    std::vector<uint16_t> host_activation(k);
    for (size_t i = 0; i < host_packed.size(); ++i)
      host_packed[i] = static_cast<uint8_t>((i * 37 + 11) & 0xff);
    for (size_t i = 0; i < host_activation.size(); ++i)
      host_activation[i] = static_cast<uint16_t>(0x3e00 + (i % 17));

    void* packed = nullptr;
    void* scale = nullptr;
    void* activation = nullptr;
    void* old_output = nullptr;
    void* new_output = nullptr;
    hip_check(hipMalloc(&packed, host_packed.size()), "hipMalloc packed");
    hip_check(hipMalloc(&scale, host_scale.size()), "hipMalloc scale");
    hip_check(hipMalloc(&activation, host_activation.size() * sizeof(uint16_t)),
              "hipMalloc activation");
    hip_check(hipMalloc(&old_output, n * sizeof(uint16_t)),
              "hipMalloc old output");
    hip_check(hipMalloc(&new_output, n * sizeof(uint16_t)),
              "hipMalloc new output");
    hip_check(hipMemcpy(packed, host_packed.data(), host_packed.size(),
                        hipMemcpyHostToDevice),
              "hipMemcpy packed");
    hip_check(hipMemcpy(scale, host_scale.data(), host_scale.size(),
                        hipMemcpyHostToDevice),
              "hipMemcpy scale");
    hip_check(hipMemcpy(activation, host_activation.data(),
                        host_activation.size() * sizeof(uint16_t),
                        hipMemcpyHostToDevice),
              "hipMemcpy activation");

    hipStream_t stream = nullptr;
    hip_check(hipStreamCreateWithFlags(&stream, hipStreamNonBlocking),
              "hipStreamCreateWithFlags");

    for (int i = 0; i < 64; ++i) {
      netra_check(old_api.linear(packed, scale, activation, old_output, 1, n, k,
                                 reinterpret_cast<void*>(stream)),
                  "old warmup");
      netra_check(new_api.linear(packed, scale, activation, new_output, 1, n, k,
                                 reinterpret_cast<void*>(stream)),
                  "new warmup");
    }
    hip_check(hipStreamSynchronize(stream), "warmup sync");

    std::vector<double> old_eager_host, new_eager_host;
    collect_eager_host(old_api, new_api, stream, packed, scale, activation,
                       old_output, new_output, n, k, host_samples,
                       old_eager_host, new_eager_host);
    std::vector<double> old_eager_gpu, new_eager_gpu;
    collect_eager_gpu(old_api, new_api, stream, packed, scale, activation,
                      old_output, new_output, n, k, event_samples,
                      old_eager_gpu, new_eager_gpu);

    // Remove the process-wide first-capture setup cost from the A/B comparison.
    Capture warm_capture = capture_linear(old_api, stream, packed, scale,
                                           activation, old_output, n, k);
    hip_check(hipGraphExecDestroy(warm_capture.exec), "destroy warm graph exec");
    hip_check(hipGraphDestroy(warm_capture.graph), "destroy warm graph");

    Capture old_capture = capture_linear(old_api, stream, packed, scale,
                                         activation, old_output, n, k);
    Capture new_capture = capture_linear(new_api, stream, packed, scale,
                                         activation, new_output, n, k);
    std::vector<double> old_graph_host, new_graph_host;
    collect_graph_host(old_capture, new_capture, stream, host_samples,
                       old_graph_host, new_graph_host);
    std::vector<double> old_graph_gpu, new_graph_gpu;
    collect_graph_gpu(old_capture, new_capture, stream, event_samples,
                      old_graph_gpu, new_graph_gpu);

    hip_check(hipGraphLaunch(old_capture.exec, stream), "final old graph launch");
    hip_check(hipGraphLaunch(new_capture.exec, stream), "final new graph launch");
    hip_check(hipStreamSynchronize(stream), "final graph output sync");
    std::vector<uint16_t> old_values(n), new_values(n);
    hip_check(hipMemcpy(old_values.data(), old_output, n * sizeof(uint16_t),
                        hipMemcpyDeviceToHost),
              "hipMemcpy old output");
    hip_check(hipMemcpy(new_values.data(), new_output, n * sizeof(uint16_t),
                        hipMemcpyDeviceToHost),
              "hipMemcpy new output");

    const Stats old_eager_host_stats = summarize(old_eager_host);
    const Stats new_eager_host_stats = summarize(new_eager_host);
    const Stats old_eager_gpu_stats = summarize(old_eager_gpu);
    const Stats new_eager_gpu_stats = summarize(new_eager_gpu);
    const Stats old_graph_host_stats = summarize(old_graph_host);
    const Stats new_graph_host_stats = summarize(new_graph_host);
    const Stats old_graph_gpu_stats = summarize(old_graph_gpu);
    const Stats new_graph_gpu_stats = summarize(new_graph_gpu);

    std::cout << std::fixed << std::setprecision(6);
    std::cout << "{\n"
              << "  \"target\": \"gfx1151\",\n"
              << "  \"status\": \"measured\",\n"
              << "  \"device\": \"" << properties.name << "\",\n"
              << "  \"host_samples_per_library\": " << host_samples << ",\n"
              << "  \"event_samples_per_library\": " << event_samples << ",\n"
              << "  \"non_default_stream\": true,\n"
              << "  \"output_bit_exact\": "
              << (old_values == new_values ? "true" : "false") << ",\n"
              << "  \"old_output_fnv1a64\": \"0x" << std::hex
              << fnv1a64(old_values) << std::dec << "\",\n"
              << "  \"new_output_fnv1a64\": \"0x" << std::hex
              << fnv1a64(new_values) << std::dec << "\",\n"
              << "  \"old_graph_nodes\": " << old_capture.node_count << ",\n"
              << "  \"new_graph_nodes\": " << new_capture.node_count << ",\n"
              << "  \"old_capture_us\": " << old_capture.capture_us << ",\n"
              << "  \"new_capture_us\": " << new_capture.capture_us << ",\n"
              << "  \"old_instantiate_us\": " << old_capture.instantiate_us
              << ",\n"
              << "  \"new_instantiate_us\": " << new_capture.instantiate_us
              << ",\n"
              << "  \"measurements\": {\n";
    print_stats("old_eager_host", old_eager_host_stats, true);
    print_stats("new_eager_host", new_eager_host_stats, true);
    print_stats("old_eager_gpu", old_eager_gpu_stats, true);
    print_stats("new_eager_gpu", new_eager_gpu_stats, true);
    print_stats("old_graph_host", old_graph_host_stats, true);
    print_stats("new_graph_host", new_graph_host_stats, true);
    print_stats("old_graph_gpu", old_graph_gpu_stats, true);
    print_stats("new_graph_gpu", new_graph_gpu_stats, false);
    std::cout << "  }\n}\n";

    hip_check(hipGraphExecDestroy(old_capture.exec), "destroy old graph exec");
    hip_check(hipGraphExecDestroy(new_capture.exec), "destroy new graph exec");
    hip_check(hipGraphDestroy(old_capture.graph), "destroy old graph");
    hip_check(hipGraphDestroy(new_capture.graph), "destroy new graph");
    hip_check(hipStreamDestroy(stream), "hipStreamDestroy");
    hip_check(hipFree(packed), "hipFree packed");
    hip_check(hipFree(scale), "hipFree scale");
    hip_check(hipFree(activation), "hipFree activation");
    hip_check(hipFree(old_output), "hipFree old output");
    hip_check(hipFree(new_output), "hipFree new output");
    dlclose(old_api.handle);
    dlclose(new_api.handle);
    return old_values == new_values ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << "\n";
    return 1;
  }
}
