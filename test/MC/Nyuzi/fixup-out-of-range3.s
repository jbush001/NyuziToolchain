# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# Long backward branch. First instruction is just in range, second is just out

foo:  .long 0

.space (1 << 26) - 4

b foo       # CHECK-NOT: fixup-out-of-range3.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
b foo       # CHECK: fixup-out-of-range3.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
