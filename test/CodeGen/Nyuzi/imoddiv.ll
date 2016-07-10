; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define i32 @urem32(i32 %a, i32 %b) { 	; CHECK: urem32:
	%1 = urem i32 %a, %b 			; CHECK: call __umodsi3
	ret i32 %1
}

define i32 @srem32(i32 %a, i32 %b) { 	; CHECK: srem32:
	%1 = srem i32 %a, %b 			; CHECK: call __modsi3
	ret i32 %1
}

define i32 @udiv32(i32 %a, i32 %b) { 	; CHECK: udiv32:
	%1 = udiv i32 %a, %b 			; CHECK: call __udivsi3
	ret i32 %1
}

define i32 @sdiv32(i32 %a, i32 %b) { 	; CHECK: sdiv32:
	%1 = sdiv i32 %a, %b 			; CHECK: call __divsi3
	ret i32 %1
}

define i64 @urem64(i64 %a, i64 %b) { 	; CHECK: urem64:
	%1 = urem i64 %a, %b 			; CHECK: call __umoddi3
	ret i64 %1
}

define i64 @srem64(i64 %a, i64 %b) { 	; CHECK: srem64:
	%1 = srem i64 %a, %b 			; CHECK: call __moddi3
	ret i64 %1
}

define i64 @udiv64(i64 %a, i64 %b) { 	; CHECK: udiv64:
	%1 = udiv i64 %a, %b 			; CHECK: call __udivdi3
	ret i64 %1
}

define i64 @sdiv64(i64 %a, i64 %b) { 	; CHECK: sdiv64:
	%1 = sdiv i64 %a, %b 			; CHECK: call __divdi3
	ret i64 %1
}
