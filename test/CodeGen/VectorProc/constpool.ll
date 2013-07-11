; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @loadconstv(i32 %a, i32 %b, <16 x i32> %c) {	; CHECK: loadconstv
	%cmp = icmp sgt i32 %a, %b
	%res = select i1 %cmp, <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>, <16 x i32> <i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0>
	; CHECK: load.v v{{[0-9]+}}, {{[A-Z0-9_a-z]+}}
	ret <16 x i32> %res
}


; CHECK: [[CONSTF_LBL:LCP[0-9A-Za-z_]+]]: 
; CHECK: .word	1075419546 
define float @loadconstf() {	; CHECK: loadconstf
  ret float 0x4003333340000000
	; CHECK: load.32 s{{[0-9]+}}, [[CONSTF_LBL]]
}

define i32 @loadconsti_little() {	; CHECK: loadconsti_little
  ret i32 13
	; CHECK: move s{{[0-9]+}}, 13
}

; CHECK: [[CONSTI_LBL:LCP[0-9A-Za-z_]+]]: 
; CHECK: .word 3735928559
define i32 @loadconsti_big() {	; CHECK: loadconsti_big
  ret i32 -559038737
	; CHECK: load.32 s{{[0-9]+}}, [[CONSTI_LBL]]
}




