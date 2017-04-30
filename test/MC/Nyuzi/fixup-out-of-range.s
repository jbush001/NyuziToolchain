# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

b foo          # CHECK: fixup-out-of-range.s:[[@LINE]]:{{[0-9]+}}: error: fixup out of range

.space 1 << 25

foo:  .long 0

