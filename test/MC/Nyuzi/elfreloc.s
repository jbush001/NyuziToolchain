# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | \
# RUN: llvm-objdump -r - | FileCheck %s

# CHECK: RELOCATION RECORDS

# These fixups will be resolved internally and will not create relocations.
foo: goto foo           # fixup_Nyuzi_PCRel_Branch
    # CHECK-NOT: foo
boo: load_32 s5, boo    # fixup_Nyuzi_PCRel_MemAccExt
    # CHECK-NOT: boo
bah: lea s3, bah        # fixup_Nyuzi_PCRel_ComputeLabelAddress
    # CHECK-NOT: bah
buz: .long buz          # FK_Data_4
    # CHECK-NOT: buz

# These fixups reference labels that are not defined here. Check that they
# create relocations.

goto memcpy     # CHECK: 00000010 R_NYUZI_BRANCH memcpy
load_32 s0, bar # CHECK: 00000014 R_NYUZI_PCREL_MEM_EXT bar
lea s1, baz     # CHECK: 00000018 R_NYUZI_PCREL_LEA baz
.long ioctl     # CHECK: 0000001c R_NYUZI_ABS32 ioctl
