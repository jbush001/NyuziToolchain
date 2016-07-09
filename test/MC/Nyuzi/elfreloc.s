# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | \
# RUN: llvm-objdump -r - | FileCheck %s


foo: goto foo	# The fixup for this will be resolved internally and will not create a
				# relocation.

	# CHECK: RELOCATION RECORDS
call memcpy
	# CHECK: 00000004 R_NYUZI_BRANCH memcpy
call exit
	# CHECK: 00000008 R_NYUZI_BRANCH exit
.long ioctl
	# CHECK: 0000000c R_NYUZI_ABS32 ioctl
load_32 s0, bar
    # CHECK: 00000010 R_NYUZI_PCREL_MEM_EXT bar
lea s1, baz
    # CHECK: 00000014 R_NYUZI_PCREL_LEA baz
