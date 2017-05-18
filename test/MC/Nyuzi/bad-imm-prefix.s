# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

movehi s0, hi 12  # CHECK: bad-imm-prefix.s:[[@LINE]]:15: error: expected '('
or s0, s0, lo 12  # CHECK: bad-imm-prefix.s:[[@LINE]]:15: error: expected '('
movehi s0, hi(12  # CHECK: bad-imm-prefix.s:[[@LINE]]:15: error: expected identifier
or s0, s0, lo(12  # CHECK: bad-imm-prefix.s:[[@LINE]]:15: error: expected identifier
movehi s0, hi(foo ]  # CHECK: bad-imm-prefix.s:[[@LINE]]:19: error: expected ')'
or s0, s0, lo(foo ]  # CHECK: bad-imm-prefix.s:[[@LINE]]:19: error: expected ')'


