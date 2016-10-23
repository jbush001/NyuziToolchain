# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# Check for invalid register types in all operands
# See issue #22

load_v s0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_v v0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v s0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v v0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_v_mask s0, s0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_v_mask v0, v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_v_mask v0, s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask s0, s0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask v0, v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_v_mask v0, s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_32 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_32 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_32 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_32 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_s16 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_s16 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u16 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u16 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_16 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_16 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_s8 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_s8 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u8 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_u8 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_8 s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_8 v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_sync s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_sync v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_sync s0, (v1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_sync v0, (s1) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction

load_gath v0, (s0) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
load_gath s0, (v0) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_scat v0, (s0) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
store_scat s0, (v0) # CHECK: bad-memory-operand4.s:[[@LINE]]:{{[0-9]+}}: error: invalid operand for instruction
