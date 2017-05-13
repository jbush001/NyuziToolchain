// REQUIRES: nyuzi
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %s -o %t
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %S/Inputs/far-nyuzi-labels.s -o %tfar
// RUN: ld.lld %t %tfar -o %t2 2>&1
// RUN: llvm-objdump -d %t2 | FileCheck %s

.globl _start
_start:
  // 0xe756d28a >> 13
  movehi s0, hi(far5)  // CHECK: movehi s0, 473782

  // 0xe756d28a & 0x1fff
  or s0, s0, lo(far5)  // CHECK: or s0, s0, 4746




