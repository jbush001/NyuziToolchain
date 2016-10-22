# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s
# XFAIL: nyuzi

# Masked immediate offset is only 10 bits

load_v_mask v0, s0, 0x7ff(s1) # CHECK: masked-mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate out of range

