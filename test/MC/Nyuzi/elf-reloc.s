# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | llvm-objdump -r - | FileCheck %s -check-prefix=CHECK-RELOC
# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s -check-prefix=CHECK-ENCODE

# CHECK: RELOCATION RECORDS

# These fixups will be resolved internally and will not create relocations.
foo: b foo
  # CHECK-RELOC-NOT: foo
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: foo, kind: fixup_Nyuzi_PCRel_Branch
boo: load_32 s5, boo
  # CHECK-RELOC-NOT: boo
  # CHECK-ENCODE: encoding: [0xbf,0bAAAAAA00,A,0b1010100A]
  # CHECK-ENCODE: fixup A - offset: 0, value: boo, kind: fixup_Nyuzi_PCRel_MemAccExt
bah: lea s3, bah
  # CHECK-RELOC-NOT: bah
  # CHECK-ENCODE: encoding: [0x7f,0bAAAAAA00,A,0x05]
  # CHECK-ENCODE: fixup A - offset: 0, value: bah, kind: fixup_Nyuzi_PCRel_ComputeLabelAddress
  buz: .long buz      # FK_Data_4
  # CHECK-RELOC-NOT: buz
bim: movehi s0, hi(bim)
     # CHECK-RELOC-NOT: bim
     # CHECK-ENCODE: encoding: [A,A,A,0x4f'A']
     # CHECK-ENCODE: fixup A - offset: 0, value: hi(bim), kind: fixup_Nyuzi_HI19
     or s0, s0, lo(bim)
     # CHECK-RELOC-NOT: bim
     # CHECK-ENCODE: encoding: [0x00,0bAAAAAA00,0b0AAAAAAA,0x00]
     # CHECK-ENCODE: fixup A - offset: 0, value: lo(bim), kind: fixup_Nyuzi_IMM_LO13

# These fixups reference labels that are not defined here. Check that they
# create relocations.

b memcpy
  # CHECK-RELOC: 00000018 R_NYUZI_BRANCH memcpy
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memcpy, kind: fixup_Nyuzi_PCRel_Branch

load_32 s0, bar
  # CHECK-RELOC: 0000001c R_NYUZI_PCREL_MEM_EXT bar
  # CHECK-ENCODE: encoding: [0x1f,0bAAAAAA00,A,0b1010100A]
  # CHECK-ENCODE: fixup A - offset: 0, value: bar, kind: fixup_Nyuzi_PCRel_MemAccExt

lea s1, baz
  # CHECK-RELOC: 00000020 R_NYUZI_PCREL_LEA baz
  # CHECK-ENCODE: encoding: [0x3f,0bAAAAAA00,A,0x05]
  # CHECK-ENCODE: fixup A - offset: 0, value: baz, kind: fixup_Nyuzi_PCRel_ComputeLabelAddress

movehi s3, hi(bam)
  # CHECK-RELOC: 00000024 R_NYUZI_HI19 bam
  # CHECK-ENCODE: encoding: [0x60'A',A,A,0x4f'A']
  # CHECK-ENCODE: fixup A - offset: 0, value: hi(bam), kind: fixup_Nyuzi_HI19

or s0, s0, lo(bam)
  # CHECK-RELOC: 00000028 R_NYUZI_IMM_LO13 bam
  # CHECK-ENCODE: encoding: [0x00,0bAAAAAA00,0b0AAAAAAA,0x00]
  # CHECK-ENCODE: fixup A - offset: 0, value: lo(bam), kind: fixup_Nyuzi_IMM_LO13

.long ioctl
  # CHECK-RELOC: 0000002c R_NYUZI_ABS32 ioctl
