; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

; These are emitted into the constant pool
; CHECK: [[FOO_LBL:LCP[0-9A-Za-z_]+]]: 
; CHECK: .word foo
; CHECK: [[BAR_LBL:LCP[0-9A-Za-z_]+]]: 
; CHECK: .word bar

define void @test() #0 {
	%1 = load i32* @foo, align 4
	store i32 %1, i32* @bar, align 4

	; CHECK: load.32 [[FOO_PTR:s[0-9]+]], [[FOO_LBL]]
	; CHECK: load.32 {{s[0-9]+}}, ([[FOO_PTR]])
	; CHECK: load.32 [[BAR_PTR:s[0-9]+]], [[BAR_LBL]]
	; CHECK: store.32 {{s[0-9]+}}, ([[BAR_PTR]])


	ret void
}
