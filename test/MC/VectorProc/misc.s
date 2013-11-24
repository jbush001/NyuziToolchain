# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

	dflush s7	; CHECK: encoding: [0x07,0x00,0x00,0xe4]
	membar		; CHECK: encoding: [0x00,0x00,0x00,0xe8]
	
foo: .word bar
	load_32 s4, foo		# CHECK: encoding: [0x9f,0bAAAAAA00,A,0b1010100A]
		# CHECK: fixup A - offset: 0, value: foo, kind: fixup_VectorProc_PCRel_MemAccExt
	