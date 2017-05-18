# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

movehi s0, hi(foo ]  # CHECK: bad-imm-prefix3.s:[[@LINE]]:19: error: expected ')'
or s0, s0, lo(foo ]  # CHECK: bad-imm-prefix3.s:[[@LINE]]:19: error: expected ')'
