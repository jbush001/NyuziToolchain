# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s
# XFAIL: nyuzi

# Only 8 bits are available in a masked instruction

add_i_mask v0, s0, v1, 0x1ff # CHECK: masked-immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate out of range

