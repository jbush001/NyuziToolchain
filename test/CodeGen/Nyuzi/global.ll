; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

; These are emitted into the constant pool
; CHECK: [[FOO_LBL:\.LCP[0-9A-Za-z_]+]]: 
; CHECK: .long foo

define i32 @test() #0 {
	%1 = load i32, i32* @foo, align 4

	; CHECK: load_32 [[FOO_PTR:s[0-9]+]], [[FOO_LBL]]
	; CHECK: load_32 {{s[0-9]+}}, ([[FOO_PTR]])

	ret i32 %1
}
