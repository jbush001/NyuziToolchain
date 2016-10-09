# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

add_i s0, s1  # CHECK: missing-operand.s:[[@LINE]]:{{[0-9]+}}: error: too few operands for instruction