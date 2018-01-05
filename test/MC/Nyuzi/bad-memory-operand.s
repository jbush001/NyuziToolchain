# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

load_32 s0, 32  # CHECK: bad-memory-operand.s:[[@LINE]]:17: error: expected (
load_32 s0, 32(bloink)  # CHECK: bad-memory-operand.s:[[@LINE]]:16: error: invalid register
load_32 s0, 32(s12  # CHECK: bad-memory-operand.s:[[@LINE]]:21: error: expected )

# Check for invalid register types in all operands (eg. vector where there
# should be a scalar). There are CHECK-NOTs here to ensure "unknown token"
# errors aren't omitted. This is a regression test, as this was happening
# previously in a number of cases.

load_v s0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
# CHECK-NOT: unknown token
load_v v0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
# CHECK-NOT: unknown token
store_v s0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
# CHECK-NOT: unknown token
store_v v0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
# CHECK-NOT: unknown token

load_v_mask s0, s0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_v_mask v0, v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_v_mask v0, s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask s0, s0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask v0, v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask v0, s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_32 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_32 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_32 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_32 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_s16 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_s16 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u16 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u16 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_16 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_16 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_s8 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_s8 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u8 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u8 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_8 s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_8 v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_sync s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_sync v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_sync s0, (v1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_sync v0, (s1) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_gath v0, (s0) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_gath s0, (v0) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_scat v0, (s0) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_scat s0, (v0) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_gath v0, got(bloink)  # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: cannot use got expression with this type of memory access
load_32 s0, floo(flum) # CHECK: bad-memory-operand.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
