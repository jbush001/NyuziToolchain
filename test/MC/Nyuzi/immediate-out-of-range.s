# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# 14 bits for non-masked instruction, 9 bits for masked
# Do boundary tests: one that is just small enough to fit, and one that is
# just too big.
# There are CHECK-NOTs here to ensure "unknown token" errors aren't omitted.
# This is a regression test, as this was happening previously in a number of
# cases.

add_i s0, s0, 0x1fff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i s0, s0, -0x2000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i s0, s0, 0x2000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
# CHECK-NOT: unknown token
add_i s0, s0, -0x2001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
# CHECK-NOT: unknown token

add_i_mask v0, s0, v1, 0xff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i_mask v0, s0, v1, -0x100 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i_mask v0, s0, v1, 0x100 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
add_i_mask v0, s0, v1, -0x101 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move s0, 0x1fff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move s0, -0x2000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move s0, 0x2000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move s0, -0x2001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move v0, 0x1fff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move v0, -0x2000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move v0, 0x2000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move v0, -0x2001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move_mask v0, s0, 0xff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move_mask v0, s0, -0x100 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move_mask v0, s0, 0x100 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move_mask v0, s0, -0x101 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

movehi s0, 0x7ffff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
movehi s0, 0x80000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

load_32 s0, 0x3fff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_32 s1, -0x4000(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_32 s2, 0x4000(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_32 s3, -0x4001(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_v v0, 0x3fff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_v v1, -0x4000(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_v v2, 0x4000(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_v v3, -0x4001(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

# Masked vector loads have a smaller immediate field
load_v_mask v0, s0, 0x1ff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_v_mask v1, s0, -0x200(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
load_v_mask v2, s0, 0x200(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_v_mask v3, s0, -0x201(s0) # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

