# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# Short (conditional) forward branch. First instruction is just in range,
# second is just out

bz s0, foo       # CHECK-NOT: fixup-out-of-range2.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
bz s0, bar       # CHECK: fixup-out-of-range2.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range

.space (1 << 21) - 12
foo:  .long 0
.long 0
bar:  .long 0
