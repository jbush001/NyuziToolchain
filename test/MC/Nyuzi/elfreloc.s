# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | llvm-objdump -r - | FileCheck %s -check-prefix=CHECK-RELOC
# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s -check-prefix=CHECK-ENCODE

# CHECK: RELOCATION RECORDS

# These fixups will be resolved internally and will not create relocations.
foo: goto foo
  # CHECK-RELOC-NOT: foo
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: foo, kind: fixup_Nyuzi_PCRel_Branch
boo: load_32 s5, boo
  # CHECK-RELOC-NOT: boo
  # CHECK-ENCODE: encoding: [0xbf,0bAAAAAA00,A,0b1010100A]
  # CHECK-ENCODE: fixup A - offset: 0, value: boo, kind: fixup_Nyuzi_PCRel_MemAccExt
bah: lea s3, bah
  # CHECK-RELOC-NOT: bah
  # CHECK-ENCODE: encoding: [0x7f,0bAAAAAA00,0b1AAAAAAA,0x02]
  # CHECK-ENCODE: fixup A - offset: 0, value: bah, kind: fixup_Nyuzi_PCRel_ComputeLabelAddress
  buz: .long buz      # FK_Data_4
  # CHECK-RELOC-NOT: buz

# These fixups reference labels that are not defined here. Check that they
# create relocations.

goto memcpy
  # CHECK-RELOC: 00000010 R_NYUZI_BRANCH memcpy
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memcpy, kind: fixup_Nyuzi_PCRel_Branch

load_32 s0, bar
  # CHECK-RELOC: 00000014 R_NYUZI_PCREL_MEM_EXT bar
  # CHECK-ENCODE: encoding: [0x1f,0bAAAAAA00,A,0b1010100A]
  # CHECK-ENCODE: fixup A - offset: 0, value: bar, kind: fixup_Nyuzi_PCRel_MemAccExt

lea s1, baz
  # CHECK-RELOC: 00000018 R_NYUZI_PCREL_LEA baz
  # CHECK-ENCODE: encoding: [0x3f,0bAAAAAA00,0b1AAAAAAA,0x02]
  # CHECK-ENCODE: fixup A - offset: 0, value: baz, kind: fixup_Nyuzi_PCRel_ComputeLabelAddress

.long ioctl
  # CHECK-RELOC: 0000001c R_NYUZI_ABS32 ioctl
