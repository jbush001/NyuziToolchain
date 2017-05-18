# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

load_32 s0, 32  # CHECK: bad-memory-operand1.s:[[@LINE]]:17: error: expected (
