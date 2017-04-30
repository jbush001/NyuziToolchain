# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

# Long forward branch. First instruction is just in range, second is just out

b foo       # CHECK-NOT: fixup-out-of-range1.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range
b bar       # CHECK: fixup-out-of-range1.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range

.space (1 << 26) - 12
foo:  .long 0
.long 0
bar:  .long 0
