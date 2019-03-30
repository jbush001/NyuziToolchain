# REQUIRES: nyuzi
# RUN: llvm-mc -filetype=obj -triple=nyuzi-none-none %s -o %t.o
# RUN: ld.lld %t.o -o %t.elf 2>&1
# RUN: llvm-objdump -s -section=.got %t.elf | FileCheck -check-prefix=GOT_CONTENTS %s
# RUN: llvm-objdump -d %t.elf | FileCheck -check-prefix=DISASM %s

.text
.globl _start
_start:   load_32 s0, got(a_symbol)(gp)   # @ 0x1000
          load_32 s1, got(b_symbol)(gp)
          load_32 s2, got(c_symbol)(gp)

          .data
          .globl a_symbol
          .globl b_symbol
          .globl c_symbol
a_symbol: .long 0                       # @ 3000
b_symbol: .long 0
c_symbol: .long 0

# There are two fixups were are checking for here:
# - Each of the GOT entries points to the proper location in the data segment
#   (these are all byte reversed because it's little endian)
# - Each of the instructions points to the proper GOT index.
# This assumes the linker will put the got at 0x2000 and the data segment at
# 0x3000, but that's not guaranteed.

# GOT_CONTENTS: Contents of section .got:
# GOT_CONTENTS: 2000 00300000 04300000 08300000
# DISASM: load_32 s0, (gp)
# DISASM: load_32 s1, 4(gp)
# DISASM: load_32 s2, 8(gp)
