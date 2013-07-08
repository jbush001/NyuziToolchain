; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @loadconstv(i32 %a, i32 %b, <16 x i32> %c) {	; CHECK: loadconstv
	%cmp = icmp sgt i32 %a, %b
	%res = select i1 %cmp, <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>, <16 x i32> <i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0>
	; CHECK: v{{[0-9]+}} = mem_l[{{[A-Z0-9_a-z]+}}]
	ret <16 x i32> %res
}

define float @loadconstf() {	; CHECK: loadconstf
  ret float 0x4003333340000000
	; CHECK: s{{[0-9]+}} = mem_l[{{[A-Z0-9_a-z]+}}]
}

define i32 @loadconsti_little() {	; CHECK: loadconsti_little
  ret i32 13
	; CHECK: s{{[0-9]+}} = 13
}

; XXX when the system is modified to use the constant pool for these, this will 
; turn into a load
define i32 @loadconsti_big() {	; CHECK: loadconsti_big
  ret i32 -559038737
	; CHECK: s{{[0-9]+}} = mem_l[{{[A-Z0-9_a-z]+}}]
}




