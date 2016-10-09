# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s
# XFAIL: nyuzi

# See issue #22. This is currently broken. It should fail because the memory operand needs
# to be a scalar type.

load_v v0, (v1) # CHECK: invalid-register-type.s:[[@LINE]]:{{[0-9]+}}: error: bad memory operand: invalid register

