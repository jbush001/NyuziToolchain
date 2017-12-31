// REQUIRES: nyuzi
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %s -o %t
// RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %S/Inputs/far-nyuzi-labels.s -o %tfar
// RUN: ld.lld %t %tfar -o %t2 2>&1
// RUN: llvm-objdump -d -triple=nyuzi-none-none %t2 | FileCheck  %s

.globl _start
_start:               // CHECK: _start:
          bz s0, far1 // CHECK: bz s0, 2097148 <_start+0x1ffffc>
          b far3      // CHECK: b 67108856 <_start+0x3fffffc>