// REQUIRES: nyuzi
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %s -o %t
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %S/Inputs/far-nyuzi-labels.s -o %tfar
// RUN: not ld.lld %t %tfar -o %t2 2>&1

.globl _start
_start:               // CHECK: _start:
          bz s0, far2   // CHECK: relocation R_NYUZI_BRANCH20 out of range
          b far4        // CHECK-NEXT: relocation R_NYUZI_BRANCH25 out of range
