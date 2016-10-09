# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s
# XFAIL: nyuzi

# See issue #21. This is currently broken. It should fail because the constant is out of
# range to be encoded in the instruction type.

add_i s0, s0, 0x12345678 # CHECK: constant-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate out of range

