# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s
# XFAIL: nyuzi

# Unmasked immediate offset is only 15 bits

load_i s0, 0xffff(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate out of range

