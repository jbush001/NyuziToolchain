# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

load_32 s0, 32(bloink)  # CHECK: bad-memory-operand2.s:[[@LINE]]:{{[0-9]+}}: error: invalid register

