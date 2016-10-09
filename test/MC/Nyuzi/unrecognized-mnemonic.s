# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

flargbh s0, s1, s2  # CHECK: unrecognized-mnemonic.s:[[@LINE]]:{{[0-9]+}}: error: unrecognized instruction mnemonic