# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

movehi s0, hi 12  # CHECK: bad-imm-prefix1.s:[[@LINE]]:15: error: expected '('
or s0, s0, lo 12  # CHECK: bad-imm-prefix1.s:[[@LINE]]:15: error: expected '('
