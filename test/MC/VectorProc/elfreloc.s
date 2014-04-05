; RUN: llvm-mc -filetype=obj -triple vectorproc-elf %s -o - | \
; RUN: llvm-objdump -r - | FileCheck %s


foo: goto foo	; The fixup for this will be resolved internally and will not create a
				; relocation.

	; CHECK: RELOCATION RECORDS
call memcpy	
	; CHECK: 00000004 R_VECTORPROC_BRANCH memcpy
call exit
	; CHECK: 00000008 R_VECTORPROC_BRANCH exit
.long ioctl
	; CHECK: 0000000c R_VECTORPROC_ABS32 ioctl
