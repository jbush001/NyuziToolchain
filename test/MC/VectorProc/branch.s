# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
	
foo:	goto target0		; CHECK: encoding: [0bAAA00000,A,A,0b1111011A]
		; CHECK: fixup A - offset: 0, value: target0, kind: fixup_VectorProc_PCRel_Branch
		
		btrue s1, target1	; CHECK: encoding: [0bAAA00001,A,A,0b1111010A]
		; CHECK: ;   fixup A - offset: 0, value: target1, kind: fixup_VectorProc_PCRel_Branch		

		bfalse s2, target2	; CHECK: encoding: [0bAAA00010,A,A,0b1111001A]
		; CHECK: ; 	fixup A - offset: 0, value: target2, kind: fixup_VectorProc_PCRel_Branch

		ball s3, target3 ; CHECK: encoding: [0bAAA00011,A,A,0b1111000A]
		; CHECK: ; 	fixup A - offset: 0, value: target3, kind: fixup_VectorProc_PCRel_Branch

		bnall s4, target4 ; CHECK: encoding: [0bAAA00100,A,A,0b1111101A]
		; CHECK: ; 	fixup A - offset: 0, value: target4, kind: fixup_VectorProc_PCRel_Branch

		call target5	; CHECK: encoding: [0bAAA00000,A,A,0b1111100A]
		; CHECK: ;   fixup A - offset: 0, value: target5, kind: fixup_VectorProc_PCRel_Branch		
		
		goto s2	; CHECK: encoding: [0xe2,0x03,0xf0,0xc0]
		
		call s3 ; CHECK: encoding: [0x63,0x00,0x00,0xfc]
		
target0: nop
target1: nop
target2: nop
target3: nop
target4: nop
target5: nop