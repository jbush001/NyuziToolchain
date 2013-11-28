# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

	dflush s7	; CHECK: encoding: [0x07,0x00,0x00,0xe4]
	membar		; CHECK: encoding: [0x00,0x00,0x00,0xe8]
	
foo: .long bar
	load_32 s4, foo		# CHECK: encoding: [0x9f,0bAAAAAA00,A,0b1010100A]
		# CHECK: fixup A - offset: 0, value: foo, kind: fixup_VectorProc_PCRel_MemAccExt

  # Load effective address of label (this converts to add_i s5, pc, <offset to label>)	
  lea s5, foo  # CHECK: encoding: [0xbf,0bAAAAAA00,0b1AAAAAAA,0x02]
