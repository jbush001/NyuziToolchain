# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
	
foo:	goto foo		; CHECK: encoding: [0bAAA00000,A,A,0b1111011A]
		; CHECK: fixup A - offset: 0, value: foo, kind: fixup_VectorProc_PCRel_Branch
		
		btrue s1, foo	; CHECK: encoding: [0bAAA00001,A,A,0b1111010A]
		; CHECK: ;   fixup A - offset: 0, value: foo, kind: fixup_VectorProc_PCRel_Branch		

		call bar	; CHECK: encoding: [0bAAA00000,A,A,0b1111100A]
		; CHECK: ;   fixup A - offset: 0, value: bar, kind: fixup_VectorProc_PCRel_Branch		

	
bar:
		
		goto s2	; CHECK: encoding: [0xe2,0x03,0xf0,0xc0]
		
		call s3 ; CHECK: encoding: [0x63,0x00,0x00,0xfc]