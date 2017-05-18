# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

movehi s0, hi(12  # CHECK: bad-imm-prefix2.s:[[@LINE]]:15: error: expected identifier
or s0, s0, lo(12  # CHECK: bad-imm-prefix2.s:[[@LINE]]:15: error: expected identifier
