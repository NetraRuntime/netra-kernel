// SPDX-License-Identifier: MIT
#pragma once

#include <array>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>

namespace netra_detail {

inline uint32_t rotr(uint32_t value, uint32_t bits) {
  return (value >> bits) | (value << (32 - bits));
}

inline std::string sha256_file(const std::string& path) {
  static constexpr std::array<uint32_t, 64> constants{{
      0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
      0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
      0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
      0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
      0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
      0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
      0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
      0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
  }};
  std::ifstream input(path, std::ios::binary);
  if (!input) throw std::runtime_error("cannot open " + path);
  std::string payload((std::istreambuf_iterator<char>(input)), {});
  if (!input.good() && !input.eof()) throw std::runtime_error("cannot read " + path);
  const uint64_t bit_length = static_cast<uint64_t>(payload.size()) * 8;
  payload.push_back(static_cast<char>(0x80));
  while (payload.size() % 64 != 56) payload.push_back('\0');
  for (int shift = 56; shift >= 0; shift -= 8)
    payload.push_back(static_cast<char>((bit_length >> shift) & 0xff));
  std::array<uint32_t, 8> hash{{
      0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
      0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19,
  }};
  for (size_t offset = 0; offset < payload.size(); offset += 64) {
    std::array<uint32_t, 64> words{};
    for (size_t i = 0; i < 16; ++i) {
      const auto* byte = reinterpret_cast<const unsigned char*>(payload.data() + offset + i * 4);
      words[i] = (uint32_t(byte[0]) << 24) | (uint32_t(byte[1]) << 16) |
                 (uint32_t(byte[2]) << 8) | uint32_t(byte[3]);
    }
    for (size_t i = 16; i < 64; ++i) {
      const uint32_t s0 = rotr(words[i-15],7) ^ rotr(words[i-15],18) ^ (words[i-15] >> 3);
      const uint32_t s1 = rotr(words[i-2],17) ^ rotr(words[i-2],19) ^ (words[i-2] >> 10);
      words[i] = words[i-16] + s0 + words[i-7] + s1;
    }
    auto state = hash;
    for (size_t i = 0; i < 64; ++i) {
      const uint32_t s1 = rotr(state[4],6) ^ rotr(state[4],11) ^ rotr(state[4],25);
      const uint32_t choice = (state[4] & state[5]) ^ (~state[4] & state[6]);
      const uint32_t temp1 = state[7] + s1 + choice + constants[i] + words[i];
      const uint32_t s0 = rotr(state[0],2) ^ rotr(state[0],13) ^ rotr(state[0],22);
      const uint32_t majority = (state[0] & state[1]) ^ (state[0] & state[2]) ^ (state[1] & state[2]);
      const uint32_t temp2 = s0 + majority;
      state[7]=state[6]; state[6]=state[5]; state[5]=state[4]; state[4]=state[3]+temp1;
      state[3]=state[2]; state[2]=state[1]; state[1]=state[0]; state[0]=temp1+temp2;
    }
    for (size_t i = 0; i < hash.size(); ++i) hash[i] += state[i];
  }
  std::ostringstream output;
  output << std::hex << std::setfill('0');
  for (uint32_t word : hash) output << std::setw(8) << word;
  return output.str();
}

inline bool valid_sha256(const std::string& value) {
  if (value.size() != 64) return false;
  for (char character : value)
    if (!((character >= '0' && character <= '9') ||
          (character >= 'a' && character <= 'f'))) return false;
  return true;
}

}  // namespace netra_detail
