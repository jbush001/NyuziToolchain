# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# 13 bits for non-masked instruction, 8 bits for masked
# There are checks here to ensure "unknown token" errors aren't omitted. This is a regression
# test, as this was happening previously in a number of cases.

add_i s0, s0, 0xfff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i s0, s0, -0x1000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i s0, s0, 0x1000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
# CHECK-NOT: unknown token
add_i s0, s0, -0x1001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
# CHECK-NOT: unknown token

add_i_mask v0, s0, v1, 0x7f # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i_mask v0, s0, v1, -0x80 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
add_i_mask v0, s0, v1, 0x80 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
add_i_mask v0, s0, v1, -0x81 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move s0, 0xfff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move s0, -0x1000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move s0, 0x1000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move s0, -0x1001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move v0, 0xfff # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move v0, -0x1000 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move v0, 0x1000 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move v0, -0x1001 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range

move_mask v0, s0, 0x7f # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move_mask v0, s0, -0x80 # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error:
move_mask v0, s0, 0x80 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
move_mask v0, s0, -0x81 # CHECK: immediate-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: immediate operand out of range
