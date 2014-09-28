# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s
	
foo: .long bar
	load_32 s4, foo		# CHECK: encoding: [0x9f,0bAAAAAA00,A,0b1010100A]
		# CHECK: fixup A - offset: 0, value: foo, kind: fixup_Nyuzi_PCRel_MemAccExt

baz: .long 12
  # Load effective address of label (this converts to add_i s5, pc, <offset to label>)	
  lea s5, baz  # CHECK: encoding: [0xbf,0bAAAAAA00,0b1AAAAAAA,0x02]
		# CHECK: fixup A - offset: 0, value: baz, kind: fixup_Nyuzi_PCRel_ComputeLabelAddress

bar:
  
ret  # CHECK: [0xe0,0x03,0xff,0xc0]
