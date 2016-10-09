# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

add_i %  # CHECK: unknown-token.s:[[@LINE]]:{{[0-9]+}}: error: unknown token in expression
