; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @urem(i32 %a, i32 %b) { 	; CHECK: urem:
	%1 = urem i32 %a, %b 			; CHECK: __umodsi3
	ret i32 %1
}

define i32 @srem(i32 %a, i32 %b) { 	; CHECK: srem:
	%1 = srem i32 %a, %b 			; CHECK: __modsi3
	ret i32 %1
}

define i32 @udiv(i32 %a, i32 %b) { 	; CHECK: udiv:
	%1 = udiv i32 %a, %b 			; CHECK: __udivsi3
	ret i32 %1
}

define i32 @sdiv(i32 %a, i32 %b) { 	; CHECK: sdiv:
	%1 = sdiv i32 %a, %b 			; CHECK: __divsi3
	ret i32 %1
}

