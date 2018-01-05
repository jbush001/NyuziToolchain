# RUN: llvm-mc -position-independent -filetype=obj -triple nyuzi-elf %s -o - | llvm-objdump -r - | FileCheck %s -check-prefix=CHECK-RELOC
# RUN: llvm-mc -position-independent -arch=nyuzi -show-encoding %s | FileCheck %s -check-prefix=CHECK-ENCODE

# CHECK: RELOCATION RECORDS


# These fixups reference labels that are not defined here. Check that they
# create relocations.

b memcpy
  # XXX needs to turn into PLT reference
  # CHECK-RELOC: 00000000 R_NYUZI_BRANCH25 memcpy
  # CHECK-ENCODE: encoding: [A,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memcpy, kind: fixup_Nyuzi_Branch25

bz s0, memset
  # XXX needs to turn into PLT reference
  # CHECK-RELOC: 00000004 R_NYUZI_BRANCH20 memset
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111001A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memset, kind: fixup_Nyuzi_Branch20

lea s1, baz
  # CHECK-RELOC: 00000008 R_NYUZI_GOT baz
  # CHECK_ENCODE: encoding: [0x00,0bAAAAA00,0bAAAAAAAA,0b000000AA]
  # CHECK-ENCODE: fixup A - offset: 0, value: baz, kind: fixup_Nyuzi_GOT

load_32 s0, got(bam2)(gp)
  # CHECK-RELOC: 0000000c R_NYUZI_GOT bam2
  # CHECK_ENCODE: encoding: [0x00,0bAAAAA00,0bAAAAAAAA,0b000000AA]
  # CHECK-ENCODE: fixup A - offset: 0, value: bam2, kind: fixup_Nyuzi_GOT
