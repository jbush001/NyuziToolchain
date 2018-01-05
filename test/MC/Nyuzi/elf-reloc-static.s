# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | llvm-objdump -r - | FileCheck %s -check-prefix=CHECK-RELOC
# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s -check-prefix=CHECK-ENCODE

# CHECK: RELOCATION RECORDS

# These fixups will be resolved internally and will not create relocations.
foo: b foo
  # CHECK-RELOC-NOT: foo
  # CHECK-ENCODE: encoding: [A,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: foo, kind: fixup_Nyuzi_Branch25

fum: bz s0, fum
  # CHECK-RELOC-NOT: fum
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111001A]
  # CHECK-ENCODE: fixup A - offset: 0, value: fum, kind: fixup_Nyuzi_Branch20

bah: lea s3, bah
  # CHECK-RELOC-NOT: bah
  # CHECK-ENCODE: encoding: [0x60'A',A,A,0x4f'A']
  # CHECK-ENCODE:   fixup A - offset: 0, value: hi(bah), kind: fixup_Nyuzi_HI19
  # CHECK-ENCODE: encoding: [0x63,0bAAAAAA00,0b0AAAAAAA,0x00]
  # CHECK-ENCODE:   fixup A - offset: 0, value: lo(bah), kind: fixup_Nyuzi_IMM_LO13



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
  # CHECK-RELOC: 0000001c R_NYUZI_BRANCH25 memcpy
  # CHECK-ENCODE: encoding: [A,A,A,0b1111011A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memcpy, kind: fixup_Nyuzi_Branch25

bz s0, memset
  # CHECK-RELOC: 00000020 R_NYUZI_BRANCH20 memset
  # CHECK-ENCODE: encoding: [0bAAA00000,A,A,0b1111001A]
  # CHECK-ENCODE: fixup A - offset: 0, value: memset, kind: fixup_Nyuzi_Branch20

lea s1, baz
  # CHECK-RELOC: 00000024 R_NYUZI_HI19 baz
  # CHECK-RELOC: 00000028 R_NYUZI_IMM_LO13 baz
	# CHECK-ENCODE: encoding: [0x20'A',A,A,0x4f'A']
  # CHECK-ENCODE:    fixup A - offset: 0, value: hi(baz), kind: fixup_Nyuzi_HI19
	# CHECK-ENCODE: encoding: [0x21,0bAAAAAA00,0b0AAAAAAA,0x00]
  # CHECK-ENCODE:    fixup A - offset: 0, value: lo(baz), kind: fixup_Nyuzi_IMM_LO13

movehi s3, hi(bam1)
  # CHECK-RELOC: 0000002c R_NYUZI_HI19 bam1
  # CHECK-ENCODE: encoding: [0x60'A',A,A,0x4f'A']
  # CHECK-ENCODE: fixup A - offset: 0, value: hi(bam1), kind: fixup_Nyuzi_HI19

or s0, s0, lo(bam1)
  # CHECK-RELOC: 00000030 R_NYUZI_IMM_LO13 bam1
  # CHECK-ENCODE: encoding: [0x00,0bAAAAAA00,0b0AAAAAAA,0x00]
  # CHECK-ENCODE: fixup A - offset: 0, value: lo(bam1), kind: fixup_Nyuzi_IMM_LO13

.long ioctl
  # CHECK-RELOC: 00000034 R_NYUZI_ABS32 ioctl
