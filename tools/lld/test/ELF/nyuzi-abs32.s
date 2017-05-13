// REQUIRES: nyuzi
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %s -o %t
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %S/Inputs/far-nyuzi-labels.s -o %tfar
// RUN: ld.lld %t %tfar -o %t2 2>&1

.globl _start
_start:
.data
  .long far5 + 0x123

  // RUN: llvm-objdump -s -section=.data %t2 | FileCheck %s

  // CHECK: Contents of section .data:
  // CHECK-NEXT: 1000 add356e7
