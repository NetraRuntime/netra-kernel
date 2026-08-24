// SPDX-License-Identifier: MIT
#include <netra/engine.h>

#include <stdio.h>

int main(void) {
  if (netra_engine_abi_version() != NETRA_ENGINE_ABI_VERSION) {
    fputs("incompatible Netra runtime ABI\n", stderr);
    return 2;
  }
  printf("Netra engine %s (ABI %u)\n", netra_engine_version(),
         netra_engine_abi_version());
  return 0;
}
