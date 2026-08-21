// SPDX-License-Identifier: MIT
#include "netra_engine_internal.h"

#include <hip/hip_runtime.h>

#include <cctype>
#include <cstdio>
#include <cstdint>
#include <fstream>
#include <limits>
#include <map>
#include <new>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace {

struct Json {
  enum Kind { Null, Bool, Number, String, Array, Object } kind = Null;
  bool boolean = false;
  uint64_t number = 0;
  std::string string;
  std::vector<Json> array;
  std::map<std::string, Json> object;

  const Json& at(const char* key) const {
    auto it = object.find(key);
    if (kind != Object || it == object.end())
      throw std::runtime_error(std::string("missing manifest field: ") + key);
    return it->second;
  }
  const Json* find(const char* key) const {
    if (kind != Object) return nullptr;
    auto it = object.find(key);
    return it == object.end() ? nullptr : &it->second;
  }
};

class Parser {
 public:
  explicit Parser(std::string source) : source_(std::move(source)) {}
  Json parse() {
    Json result = value();
    whitespace();
    if (position_ != source_.size()) fail("trailing data");
    return result;
  }

 private:
  std::string source_;
  size_t position_ = 0;
  [[noreturn]] void fail(const char* message) const {
    throw std::runtime_error(std::string("JSON ") + message + " at byte " +
                             std::to_string(position_));
  }
  void whitespace() {
    while (position_ < source_.size() &&
           std::isspace(static_cast<unsigned char>(source_[position_]))) ++position_;
  }
  bool consume(char c) {
    whitespace();
    if (position_ < source_.size() && source_[position_] == c) {
      ++position_; return true;
    }
    return false;
  }
  Json value() {
    whitespace();
    if (position_ >= source_.size()) fail("unexpected end");
    const char c = source_[position_];
    if (c == '"') { Json j; j.kind = Json::String; j.string = string(); return j; }
    if (c == '{') return object();
    if (c == '[') return array();
    if (c >= '0' && c <= '9') return number();
    if (source_.compare(position_, 4, "true") == 0) { position_ += 4; Json j; j.kind=Json::Bool; j.boolean=true; return j; }
    if (source_.compare(position_, 5, "false") == 0) { position_ += 5; Json j; j.kind=Json::Bool; return j; }
    if (source_.compare(position_, 4, "null") == 0) { position_ += 4; return Json{}; }
    fail("invalid value");
  }
  std::string string() {
    if (!consume('"')) fail("expected string");
    std::string result;
    while (position_ < source_.size()) {
      char c = source_[position_++];
      if (c == '"') return result;
      if (c == '\\') {
        if (position_ >= source_.size()) fail("unterminated escape");
        char escaped = source_[position_++];
        switch (escaped) {
          case '"': case '\\': case '/': result.push_back(escaped); break;
          case 'b': result.push_back('\b'); break; case 'f': result.push_back('\f'); break;
          case 'n': result.push_back('\n'); break; case 'r': result.push_back('\r'); break;
          case 't': result.push_back('\t'); break;
          default: fail("unsupported escape");
        }
      } else {
        if (static_cast<unsigned char>(c) < 0x20) fail("control character in string");
        result.push_back(c);
      }
    }
    fail("unterminated string");
  }
  Json number() {
    Json j; j.kind = Json::Number;
    uint64_t value = 0;
    while (position_ < source_.size() && std::isdigit(static_cast<unsigned char>(source_[position_]))) {
      unsigned digit = static_cast<unsigned>(source_[position_++] - '0');
      if (value > (std::numeric_limits<uint64_t>::max() - digit) / 10) fail("integer overflow");
      value = value * 10 + digit;
    }
    j.number = value; return j;
  }
  Json array() {
    Json j; j.kind = Json::Array; consume('[');
    if (consume(']')) return j;
    for (;;) { j.array.push_back(value()); if (consume(']')) return j; if (!consume(',')) fail("expected comma"); }
  }
  Json object() {
    Json j; j.kind = Json::Object; consume('{');
    if (consume('}')) return j;
    for (;;) {
      whitespace(); if (position_ >= source_.size() || source_[position_] != '"') fail("expected object key");
      std::string key = string(); if (!consume(':')) fail("expected colon");
      if (!j.object.emplace(std::move(key), value()).second) fail("duplicate object key");
      if (consume('}')) return j; if (!consume(',')) fail("expected comma");
    }
  }
};

std::string read_file(const std::string& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input) throw std::runtime_error("cannot open " + path);
  std::ostringstream stream; stream << input.rdbuf();
  if (!input.good() && !input.eof()) throw std::runtime_error("cannot read " + path);
  return stream.str();
}

uint32_t u32(const Json& value, const char* name) {
  if (value.kind != Json::Number || value.number > UINT32_MAX)
    throw std::runtime_error(std::string(name) + " must be uint32");
  return static_cast<uint32_t>(value.number);
}
uint64_t u64(const Json& value, const char* name) {
  if (value.kind != Json::Number)
    throw std::runtime_error(std::string(name) + " must be uint64");
  return value.number;
}
const std::string& text(const Json& value, const char* name) {
  if (value.kind != Json::String) throw std::runtime_error(std::string(name) + " must be a string");
  return value.string;
}

std::pair<uint32_t, uint32_t> rocm_major_minor(const std::string& value) {
  const size_t dot = value.find('.');
  if (dot == std::string::npos || dot == 0 || dot + 1 == value.size())
    throw std::runtime_error("required_rocm.minimum must be MAJOR.MINOR");
  const std::string major_text = value.substr(0, dot);
  const size_t next_dot = value.find('.', dot + 1);
  if (next_dot != std::string::npos)
    throw std::runtime_error("required_rocm.minimum must be MAJOR.MINOR");
  const std::string minor_text = value.substr(
      dot + 1);
  for (char c : major_text)
    if (!std::isdigit(static_cast<unsigned char>(c)))
      throw std::runtime_error("required_rocm.minimum has invalid major version");
  for (char c : minor_text)
    if (!std::isdigit(static_cast<unsigned char>(c)))
      throw std::runtime_error("required_rocm.minimum has invalid minor version");
  const unsigned long major = std::stoul(major_text);
  const unsigned long minor = std::stoul(minor_text);
  if (major > UINT32_MAX || minor > UINT32_MAX)
    throw std::runtime_error("required_rocm.minimum version overflows uint32");
  return {static_cast<uint32_t>(major), static_cast<uint32_t>(minor)};
}

std::string checked_hsaco_path(const std::string& relative) {
  if (relative.rfind("hsaco/", 0) != 0 || relative.size() <= 6 ||
      relative.find('\\') != std::string::npos ||
      relative.find("//") != std::string::npos)
    throw std::runtime_error("hsaco must be a normalized engine-relative path");
  size_t begin = 0;
  while (begin < relative.size()) {
    const size_t end = relative.find('/', begin);
    const std::string component = relative.substr(
        begin, end == std::string::npos ? std::string::npos : end - begin);
    if (component.empty() || component == "." || component == "..")
      throw std::runtime_error("hsaco path traversal is forbidden");
    if (end == std::string::npos) break;
    begin = end + 1;
  }
  return relative;
}

void set_error(netra_engine* engine, const char* message) noexcept {
  if (engine) std::snprintf(engine->last_error.data(), engine->last_error.size(), "%s", message);
}
netra_status_t fail(netra_engine* engine, netra_status_t status, const char* message) {
  set_error(engine, message);
  return status;
}
netra_status_t hip_fail(netra_engine* engine, const char* operation, hipError_t error) {
  if (engine) std::snprintf(engine->last_error.data(), engine->last_error.size(),
                            "%s: %s", operation, hipGetErrorString(error));
  return NETRA_STATUS_HIP;
}

bool guard_matches(const netra_profile_info_t& info, const netra_launch_shape_t& shape) {
  return shape.m >= info.min_m && shape.m <= info.max_m &&
         shape.batch >= info.min_batch && shape.batch <= info.max_batch &&
         shape.sequence >= info.min_sequence && shape.sequence <= info.max_sequence &&
         shape.tensor_parallel == info.tensor_parallel;
}

netra_status_t direct_launch(netra_engine* engine, netra_profile_record& profile,
                             hipStream_t stream) {
  for (auto& op : profile.operations) {
    if (op.fallback) return fail(engine, NETRA_STATUS_FALLBACK_REQUIRED,
                                 "profile contains a framework fallback operation");
    for (uint32_t i = 0; i < op.argument_count; ++i)
      if (op.argument_bindable[i] && !op.argument_values[i])
        return fail(engine, NETRA_STATUS_BINDING, "kernel pointer argument is unbound");
    hipError_t error = hipModuleLaunchKernel(op.function, op.grid[0], op.grid[1], op.grid[2],
        op.block[0], op.block[1], op.block[2], op.dynamic_lds_bytes, stream,
        op.argument_addresses.data(), nullptr);
    if (error != hipSuccess) return hip_fail(engine, "hipModuleLaunchKernel", error);
  }
  return NETRA_STATUS_OK;
}

netra_status_t launch_one(netra_engine* engine, netra_operation_record& op,
                          hipStream_t stream) {
  if (op.fallback)
    return fail(engine, NETRA_STATUS_FALLBACK_REQUIRED,
                "operation requires framework fallback");
  for (uint32_t i = 0; i < op.argument_count; ++i)
    if (op.argument_bindable[i] && !op.argument_values[i])
      return fail(engine, NETRA_STATUS_BINDING,
                  "kernel pointer argument is unbound");
  const hipError_t error = hipModuleLaunchKernel(
      op.function, op.grid[0], op.grid[1], op.grid[2], op.block[0], op.block[1],
      op.block[2], op.dynamic_lds_bytes, stream, op.argument_addresses.data(), nullptr);
  return error == hipSuccess ? NETRA_STATUS_OK
                             : hip_fail(engine, "hipModuleLaunchKernel", error);
}

}  // namespace

extern "C" netra_status_t netra_engine_create(
    const char* directory, const netra_engine_options_t* options,
    netra_engine_t** output) {
  if (!directory || !*directory || !options || !output ||
      options->struct_size != sizeof(netra_engine_options_t))
    return NETRA_STATUS_INVALID_ARGUMENT;
  *output = nullptr;
  netra_engine* engine = new (std::nothrow) netra_engine;
  if (!engine) return NETRA_STATUS_IO;
  int previous = -1;
  try {
    engine->directory = directory; engine->device_id = options->device_id;
    engine->graph_enabled = options->enable_graph_capture != 0;
    hipError_t error = hipGetDevice(&previous);
    if (error != hipSuccess) { auto status=hip_fail(engine,"hipGetDevice",error); delete engine; return status; }
    error = hipSetDevice(engine->device_id);
    if (error != hipSuccess) { auto status=hip_fail(engine,"hipSetDevice",error); delete engine; return status; }
    hipDeviceProp_t properties{}; error = hipGetDeviceProperties(&properties, engine->device_id);
    if (error != hipSuccess) { auto status=hip_fail(engine,"hipGetDeviceProperties",error); (void)hipSetDevice(previous); delete engine; return status; }
    if (std::string(properties.gcnArchName).rfind("gfx950", 0) != 0 ||
        properties.warpSize != 64) {
      (void)hipSetDevice(previous);
      delete engine; return NETRA_STATUS_UNSUPPORTED_TARGET;
    }
    Json root = Parser(read_file(engine->directory + "/engine.json")).parse();
    if (text(root.at("format_version"), "format_version") != "netra-engine-1" ||
        text(root.at("target"), "target") != "gfx950" || u32(root.at("wave_size"), "wave_size") != 64)
      throw std::runtime_error("engine target/format/wave contract mismatch");
    const Json& required_rocm = root.at("required_rocm");
    if (u32(required_rocm.at("code_object_version"), "code_object_version") != 6)
      throw std::runtime_error("only AMDHSA code object version 6 is supported");
    const auto required_version = rocm_major_minor(
        text(required_rocm.at("minimum"), "required_rocm.minimum"));
    int runtime_version = 0;
    error = hipRuntimeGetVersion(&runtime_version);
    if (error != hipSuccess)
      throw std::runtime_error(std::string("hipRuntimeGetVersion: ") +
                               hipGetErrorString(error));
    const std::pair<uint32_t, uint32_t> actual_version{
        static_cast<uint32_t>(runtime_version / 10000000),
        static_cast<uint32_t>((runtime_version / 100000) % 100)};
    if (actual_version < required_version)
      throw std::runtime_error("HIP runtime is older than required_rocm.minimum");
    engine->workspace_bytes = u64(root.at("workspace_bytes"), "workspace_bytes");
    if (engine->workspace_bytes > std::numeric_limits<size_t>::max())
      throw std::runtime_error("workspace_bytes exceeds host size_t");
    if (engine->workspace_bytes) {
      error = hipMalloc(&engine->workspace, static_cast<size_t>(engine->workspace_bytes));
      if (error != hipSuccess) { auto status=hip_fail(engine,"hipMalloc(workspace)",error); (void)hipSetDevice(previous); delete engine; return status; }
    }
    const Json& profiles = root.at("profiles");
    const Json& operations = root.at("operations");
    if (profiles.kind != Json::Array || operations.kind != Json::Array)
      throw std::runtime_error("profiles and operations must be arrays");
    if (profiles.array.size() > UINT32_MAX || operations.array.size() > UINT32_MAX)
      throw std::runtime_error("profile or operation count exceeds uint32");
    for (size_t profile_index = 0; profile_index < profiles.array.size(); ++profile_index) {
      engine->profiles.emplace_back();
      netra_profile_record& record = engine->profiles.back();
      record.operations.reserve(operations.array.size());
      record.info.struct_size = sizeof(record.info);
      record.info.profile_id = static_cast<uint32_t>(profile_index);
      const Json& p = profiles.array[profile_index]; const Json& guards = p.at("guards");
      const Json& mg = guards.at("m"); const Json& bg = guards.at("batch"); const Json& sg = guards.at("sequence");
      record.info.min_m=u32(mg.at("min"),"m.min"); record.info.max_m=u32(mg.at("max"),"m.max");
      record.info.min_batch=u32(bg.at("min"),"batch.min"); record.info.max_batch=u32(bg.at("max"),"batch.max");
      record.info.min_sequence=u64(sg.at("min"),"sequence.min"); record.info.max_sequence=u64(sg.at("max"),"sequence.max");
      record.info.tensor_parallel=u32(p.at("tensor_parallel"),"tensor_parallel");
      record.info.workspace_bytes=engine->workspace_bytes;
      for (const Json& operation : operations.array) {
        record.operations.emplace_back();
        netra_operation_record& op = record.operations.back();
        op.fallback = text(operation.at("execution"), "execution") != "kernel";
        if (op.fallback) record.info.requires_fallback = 1;
        const Json* launch = operation.find("launch");
        if (launch && launch->kind == Json::Object) {
          const Json& grid=launch->at("grid"); const Json& block=launch->at("block");
          if (grid.kind != Json::Array || block.kind != Json::Array ||
              grid.array.size() != 3 || block.array.size() != 3)
            throw std::runtime_error("launch grid and block must have three dimensions");
          for (int i=0;i<3;++i) {
            op.grid[i]=u32(grid.array[i],"grid"); op.block[i]=u32(block.array[i],"block");
            if (!op.grid[i] || !op.block[i])
              throw std::runtime_error("launch dimensions must be nonzero");
          }
          op.lds_bytes=u32(launch->at("lds_bytes"),"lds_bytes");
          const Json* dynamic_lds = launch->find("dynamic_lds_bytes");
          op.dynamic_lds_bytes = dynamic_lds
                                     ? u32(*dynamic_lds, "dynamic_lds_bytes")
                                     : 0;
        }
        // Future selected-kernel manifests carry hsaco and kernel_symbol. The
        // stage-1 compatibility engine intentionally contains fallbacks only.
        if (!op.fallback) {
          const Json& hsaco = operation.at("hsaco"); const Json& symbol = operation.at("kernel_symbol");
          const std::string relative_hsaco = checked_hsaco_path(text(hsaco,"hsaco"));
          error = hipModuleLoad(&op.module, (engine->directory + "/" + relative_hsaco).c_str());
          if (error != hipSuccess) throw std::runtime_error(std::string("hipModuleLoad: ")+hipGetErrorString(error));
          error = hipModuleGetFunction(&op.function, op.module, text(symbol,"kernel_symbol").c_str());
          if (error != hipSuccess) throw std::runtime_error(std::string("hipModuleGetFunction: ")+hipGetErrorString(error));
          const Json& arguments=operation.at("arguments");
          if (arguments.kind != Json::Array || arguments.array.empty())
            throw std::runtime_error("selected kernel requires typed arguments");
          op.argument_count=static_cast<uint32_t>(arguments.array.size());
          if (op.argument_count > op.argument_values.size())
            throw std::runtime_error("more than 32 kernel arguments");
          for (uint32_t i=0;i<op.argument_count;++i) {
            const Json& argument=arguments.array[i];
            const std::string& kind=text(argument.at("kind"),"argument.kind");
            if (kind == "pointer") {
              const Json* source=argument.find("source");
              const std::string source_name=source ? text(*source,"argument.source") : "binding";
              if (source_name == "binding") {
                op.argument_bindable[i]=true;
              } else if (source_name == "workspace") {
                const Json& offset_json=argument.at("workspace_offset");
                if (offset_json.kind != Json::Number ||
                    offset_json.number >= engine->workspace_bytes || !engine->workspace)
                  throw std::runtime_error("kernel workspace argument is out of range");
                op.argument_values[i]=static_cast<void*>(
                    static_cast<unsigned char*>(engine->workspace)+offset_json.number);
              } else {
                throw std::runtime_error("unsupported pointer argument source: "+source_name);
              }
            } else if (kind == "u32_constant") {
              op.scalar_u32[i]=u32(argument.at("value"),"argument.value");
              op.argument_is_u32[i]=true;
            } else {
              throw std::runtime_error("unsupported kernel argument kind: "+kind);
            }
            op.argument_addresses[i] = op.argument_is_u32[i]
                                           ? static_cast<void*>(&op.scalar_u32[i])
                                           : static_cast<void*>(&op.argument_values[i]);
          }
        }
      }
    }
    (void)hipSetDevice(previous); engine->last_error[0] = '\0'; *output=engine;
    return NETRA_STATUS_OK;
  } catch (const std::exception& exception) {
    set_error(engine, exception.what());
    for (auto& p : engine->profiles) for (auto& op : p.operations) if (op.module) (void)hipModuleUnload(op.module);
    if (engine->workspace) (void)hipFree(engine->workspace);
    if (previous >= 0) (void)hipSetDevice(previous);
    delete engine; return NETRA_STATUS_MANIFEST;
  }
}

extern "C" size_t netra_engine_profile_count(const netra_engine_t* engine) {
  return engine ? engine->profiles.size() : 0;
}
extern "C" netra_status_t netra_engine_query_profile(const netra_engine_t* engine,
    uint32_t profile_id, netra_profile_info_t* output) {
  if (!engine || !output || output->struct_size != sizeof(netra_profile_info_t)) return NETRA_STATUS_INVALID_ARGUMENT;
  if (profile_id >= engine->profiles.size()) return NETRA_STATUS_UNSUPPORTED_PROFILE;
  *output=engine->profiles[profile_id].info; return NETRA_STATUS_OK;
}
extern "C" netra_status_t netra_engine_bind(netra_engine_t* engine, uint32_t profile_id,
    uint32_t operation_index, uint32_t argument_index, void* pointer) {
  if (!engine || !pointer) return NETRA_STATUS_INVALID_ARGUMENT;
  if (engine->bindings_finalized.load(std::memory_order_acquire))
    return fail(engine,NETRA_STATUS_BUSY,"bindings are finalized and immutable");
  if (engine->in_flight.load(std::memory_order_acquire)) return fail(engine,NETRA_STATUS_BUSY,"cannot bind during launch");
  if (profile_id>=engine->profiles.size() || operation_index>=engine->profiles[profile_id].operations.size()) return fail(engine,NETRA_STATUS_BINDING,"binding index out of range");
  auto& op=engine->profiles[profile_id].operations[operation_index];
  if (engine->profiles[profile_id].graph_prepared)
    return fail(engine,NETRA_STATUS_BUSY,"bindings are immutable after graph preparation");
  if (argument_index>=op.argument_count) return fail(engine,NETRA_STATUS_BINDING,"argument index out of range");
  if (!op.argument_bindable[argument_index])
    return fail(engine,NETRA_STATUS_BINDING,"constant kernel arguments cannot be rebound");
  op.argument_values[argument_index]=pointer; engine->last_error[0] = '\0'; return NETRA_STATUS_OK;
}
extern "C" netra_status_t netra_engine_finalize_bindings(netra_engine_t* engine) {
  if (!engine) return NETRA_STATUS_INVALID_ARGUMENT;
  if (engine->in_flight.load(std::memory_order_acquire))
    return fail(engine,NETRA_STATUS_BUSY,"cannot finalize bindings during launch");
  for (const auto& profile : engine->profiles)
    for (const auto& op : profile.operations)
      for (uint32_t i = 0; i < op.argument_count; ++i)
        if (op.argument_bindable[i] && !op.argument_values[i])
          return fail(engine,NETRA_STATUS_BINDING,
                      "all direct-launch pointers must be bound before finalization");
  engine->bindings_finalized.store(true,std::memory_order_release);
  engine->last_error[0] = '\0';
  return NETRA_STATUS_OK;
}
extern "C" netra_status_t netra_engine_prepare_profile(netra_engine_t* engine,
    uint32_t profile_id, hipStream_t stream) {
  if (!engine || profile_id>=engine->profiles.size()) return NETRA_STATUS_INVALID_ARGUMENT;
  auto& profile=engine->profiles[profile_id]; if (!engine->graph_enabled) return NETRA_STATUS_OK;
  if (profile.graph_prepared) return NETRA_STATUS_OK;
  if (profile.info.requires_fallback) return fail(engine,NETRA_STATUS_FALLBACK_REQUIRED,"fallback profile cannot be captured by Netra runtime");
  const netra_status_t finalize_status=netra_engine_finalize_bindings(engine);
  if(finalize_status!=NETRA_STATUS_OK)return finalize_status;
  hipError_t error=hipStreamBeginCapture(stream,hipStreamCaptureModeThreadLocal); if(error!=hipSuccess)return hip_fail(engine,"hipStreamBeginCapture",error);
  netra_status_t status=direct_launch(engine,profile,stream);
  if(status!=NETRA_STATUS_OK){ (void)hipStreamEndCapture(stream,&profile.graph); profile.graph=nullptr; return status; }
  error=hipStreamEndCapture(stream,&profile.graph); if(error!=hipSuccess)return hip_fail(engine,"hipStreamEndCapture",error);
  error=hipGraphInstantiate(&profile.graph_exec,profile.graph,nullptr,nullptr,0); if(error!=hipSuccess)return hip_fail(engine,"hipGraphInstantiate",error);
  profile.graph_prepared=true; return NETRA_STATUS_OK;
}
extern "C" netra_status_t netra_engine_launch(netra_engine_t* engine, uint32_t profile_id,
    const netra_launch_shape_t* shape, hipStream_t stream) {
  if (!engine || !shape || profile_id>=engine->profiles.size()) return NETRA_STATUS_INVALID_ARGUMENT;
  int device=-1; hipError_t error=hipGetDevice(&device); if(error!=hipSuccess)return hip_fail(engine,"hipGetDevice",error);
  if(device!=engine->device_id)return fail(engine,NETRA_STATUS_UNSUPPORTED_TARGET,"caller stream/device does not belong to engine device");
  auto& profile=engine->profiles[profile_id]; if(!guard_matches(profile.info,*shape))return fail(engine,NETRA_STATUS_UNSUPPORTED_PROFILE,"exact/bounded profile guard failed; framework fallback required");
  if(profile.info.requires_fallback)
    return fail(engine,NETRA_STATUS_FALLBACK_REQUIRED,
                "profile contains a framework fallback operation");
  if(!profile.graph_prepared && !engine->bindings_finalized.load(std::memory_order_acquire))
    return fail(engine,NETRA_STATUS_BINDING,"direct-launch bindings were not finalized");
  engine->in_flight.fetch_add(1,std::memory_order_acq_rel);
  netra_status_t status;
  if(profile.graph_prepared){ error=hipGraphLaunch(profile.graph_exec,stream); status=error==hipSuccess?NETRA_STATUS_OK:hip_fail(engine,"hipGraphLaunch",error); }
  else status=direct_launch(engine,profile,stream);
  engine->in_flight.fetch_sub(1,std::memory_order_acq_rel); return status;
}
extern "C" netra_status_t netra_engine_launch_operation(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape, hipStream_t stream) {
  if (!engine || !shape || profile_id >= engine->profiles.size() ||
      operation_index >= engine->profiles[profile_id].operations.size())
    return NETRA_STATUS_INVALID_ARGUMENT;
  int device = -1;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return hip_fail(engine, "hipGetDevice", error);
  if (device != engine->device_id)
    return fail(engine, NETRA_STATUS_UNSUPPORTED_TARGET,
                "caller stream/device does not belong to engine device");
  auto& profile = engine->profiles[profile_id];
  if (!guard_matches(profile.info, *shape))
    return fail(engine, NETRA_STATUS_UNSUPPORTED_PROFILE,
                "exact/bounded profile guard failed; framework fallback required");
  if (profile.graph_prepared)
    return fail(engine, NETRA_STATUS_BUSY,
                "individual operations cannot launch after graph preparation");
  if (profile.operations[operation_index].fallback)
    return fail(engine,NETRA_STATUS_FALLBACK_REQUIRED,
                "operation requires framework fallback");
  if (!engine->bindings_finalized.load(std::memory_order_acquire))
    return fail(engine,NETRA_STATUS_BINDING,
                "direct-launch bindings were not finalized");
  engine->in_flight.fetch_add(1, std::memory_order_acq_rel);
  const netra_status_t status =
      launch_one(engine, profile.operations[operation_index], stream);
  engine->in_flight.fetch_sub(1, std::memory_order_acq_rel);
  return status;
}
extern "C" netra_status_t netra_engine_launch_operation_bound(
    netra_engine_t* engine, uint32_t profile_id, uint32_t operation_index,
    const netra_launch_shape_t* shape,
    const netra_pointer_binding_t* bindings, uint32_t binding_count,
    hipStream_t stream) {
  if (!engine || !shape || profile_id >= engine->profiles.size() ||
      operation_index >= engine->profiles[profile_id].operations.size() ||
      (binding_count && !bindings) || binding_count > 16)
    return NETRA_STATUS_INVALID_ARGUMENT;
  int device = -1;
  hipError_t error = hipGetDevice(&device);
  if (error != hipSuccess) return hip_fail(engine, "hipGetDevice", error);
  if (device != engine->device_id)
    return fail(engine, NETRA_STATUS_UNSUPPORTED_TARGET,
                "caller stream/device does not belong to engine device");
  auto& profile = engine->profiles[profile_id];
  if (!guard_matches(profile.info, *shape))
    return fail(engine, NETRA_STATUS_UNSUPPORTED_PROFILE,
                "exact/bounded profile guard failed; framework fallback required");
  if (profile.graph_prepared)
    return fail(engine, NETRA_STATUS_BUSY,
                "operation bindings are immutable after graph preparation");
  auto& op = profile.operations[operation_index];
  uint32_t expected_bindings = 0;
  for (uint32_t argument = 0; argument < op.argument_count; ++argument)
    if (op.argument_bindable[argument]) ++expected_bindings;
  if (binding_count != expected_bindings)
    return fail(engine, NETRA_STATUS_BINDING,
                "bound operation must provide every declared pointer slot");
  for (uint32_t i = 0; i < binding_count; ++i) {
    const uint32_t argument = bindings[i].argument_index;
    if (bindings[i].reserved || !bindings[i].pointer ||
        argument >= op.argument_count || !op.argument_bindable[argument])
      return fail(engine, NETRA_STATUS_BINDING,
                  "bound operation contains an invalid pointer slot");
    for (uint32_t previous = 0; previous < i; ++previous)
      if (bindings[previous].argument_index == argument)
        return fail(engine, NETRA_STATUS_BINDING,
                    "bound operation contains a duplicate pointer slot");
  }
  std::array<void*, 16> launch_values{};
  std::array<void*, 16> launch_addresses{};
  for (uint32_t i = 0; i < op.argument_count; ++i) {
    if (!op.argument_bindable[i]) launch_values[i] = op.argument_values[i];
    launch_addresses[i] = op.argument_is_u32[i]
                              ? static_cast<void*>(&op.scalar_u32[i])
                              : static_cast<void*>(&launch_values[i]);
  }
  for (uint32_t i = 0; i < binding_count; ++i)
    launch_values[bindings[i].argument_index] = bindings[i].pointer;
  engine->in_flight.fetch_add(1, std::memory_order_acq_rel);
  const hipError_t launch_error = hipModuleLaunchKernel(
      op.function, op.grid[0], op.grid[1], op.grid[2], op.block[0], op.block[1],
      op.block[2], op.dynamic_lds_bytes, stream, launch_addresses.data(), nullptr);
  const netra_status_t status =
      launch_error == hipSuccess
          ? NETRA_STATUS_OK
          : hip_fail(engine, "hipModuleLaunchKernel", launch_error);
  engine->in_flight.fetch_sub(1, std::memory_order_acq_rel);
  return status;
}
extern "C" const char* netra_engine_last_error(const netra_engine_t* engine) {
  return engine ? engine->last_error.data() : "netra_engine is null";
}
extern "C" netra_status_t netra_engine_destroy(netra_engine_t* engine) {
  if(!engine)return NETRA_STATUS_OK; if(engine->in_flight.load(std::memory_order_acquire))return fail(engine,NETRA_STATUS_BUSY,"launches remain in flight");
  for(auto& p:engine->profiles){ if(p.graph_exec)(void)hipGraphExecDestroy(p.graph_exec); if(p.graph)(void)hipGraphDestroy(p.graph); for(auto& op:p.operations)if(op.module)(void)hipModuleUnload(op.module); }
  if(engine->workspace)(void)hipFree(engine->workspace); delete engine; return NETRA_STATUS_OK;
}
