# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

load_32 s0, 32(s12  # CHECK: bad-memory-operand3.s:[[@LINE]]:{{[0-9]+}}: error: missing )

