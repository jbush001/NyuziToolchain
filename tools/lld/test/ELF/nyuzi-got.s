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
a_symbol: .long 0                       # @ 2000
b_symbol: .long 0
c_symbol: .long 0

# There are two fixups were are checking for here:
# - Each of the GOT entries points to the proper location in the data segment
#   (these are all byte reversed because it's little endian)
# - Each of the instructions points to the proper GOT index.

# GOT_CONTENTS: Contents of section .got:
# GOT_CONTENTS: 3000 00200000 04200000 08200000
# DISASM: load_32 s0, (gp)
# DISASM: load_32 s1, 4(gp)
# DISASM: load_32 s2, 8(gp)




