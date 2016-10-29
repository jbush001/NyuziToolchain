# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf %s -o /dev/null 2>&1 | FileCheck  %s

# Unmasked immediate offset is 15 bits
# Masked immediate offset is 10 bits
# Do boundary tests: one that is just small enough to fit, and one that is
# just too big.
# There are CHECK-NOTs here to ensure "unknown token" errors aren't omitted.
# This is a regression test, as this was happening previously in a number of
# cases.

load_32 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_32 s0, -0x4000(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_32 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
# CHECK-NOT: unknown token
load_32 s0, -0x4001(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
# CHECK-NOT: unknown token
load_sync s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_sync s0, -0x4000(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_sync s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_sync s0, -0x4001(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

store_32 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_32 s0, -0x4000(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_32 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_32 s0, -0x4001(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_sync s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_sync s0, -0x4000(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_sync s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_sync s0, -0x4001(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

load_s16 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_u16 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_16 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_16 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error

load_s8 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_u8 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_8 s0, 0x4000(s1) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_8 s0, 0x3fff(s1) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error

load_v v0, 0x3fff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_v v0, -0x4000(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_v v0, 0x4000(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_v v0, -0x4001(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_v v0, 0x3fff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_v v0, -0x4000(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_v v0, 0x4000(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_v v0, -0x4001(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

load_v_mask v0, s0, 0x1ff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_v_mask v0, s0, -0x200(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_v_mask v0, s0, 0x200(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_v_mask v0, s0, -0x201(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_v_mask v0, s0, 0x1ff(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_v_mask v0, s0, -0x200(s0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_v_mask v0, s0, 0x200(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_v_mask v0, s0, -0x201(s0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

load_gath v0, 0x3fff(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_gath v0, -0x4000(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_gath v0, 0x4000(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_gath v0, -0x4001(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_scat v0, 0x3fff(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_scat v0, -0x4000(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_scat v0, 0x4000(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_scat v0, -0x4001(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range

load_gath_mask v0, s0, 0x1ff(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_gath_mask v0, s0, -0x200(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
load_gath_mask v0, s0, 0x200(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
load_gath_mask v0, s0, -0x201(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_scat_mask v0, s0, 0x1ff(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_scat_mask v0, s0, -0x200(v0) # CHECK-NOT: [[@LINE]]:{{[0-9]+}}: error
store_scat_mask v0, s0, 0x200(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
store_scat_mask v0, s0, -0x201(v0) # CHECK: mem-offset-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: offset out of range
