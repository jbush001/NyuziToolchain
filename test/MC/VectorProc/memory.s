# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

bar: load.32 s1, (s2) 	# CHECK: encoding: [0x22,0x00,0x00,0xa8]
	 load.32 s1, 12(s2)	# CHECK: encoding: [0x22,0x0c,0x00,0xa8]

foo:  .word bar
	load.32 s4, foo		# CHECK: encoding: [0x9f,0bAAAAAA00,A,0b1010100A]
		# CHECK: fixup A - offset: 0, value: foo, kind: fixup_VectorProc_PCRel_MemAccExt
