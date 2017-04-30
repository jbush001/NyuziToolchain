# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# Long backward branch. First instruction is just in range, second is just out

foo:  .long 0

.space (1 << 21) - 4

bz s0, foo       # CHECK-NOT: fixup-out-of-range4.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
bz s0, foo       # CHECK: fixup-out-of-range4.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
