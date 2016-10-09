# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

add_i kaplow  # CHECK: invalid-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction