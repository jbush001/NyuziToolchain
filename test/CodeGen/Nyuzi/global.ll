; RUN: llc %s -o - | FileCheck %s
;
; Test global variable accesses
;

target triple = "nyuzi-elf-none"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

; Global addresses are emitted into the constant pool
; CHECK: [[FOO_LBL:\.LCP[0-9A-Za-z_]+]]:
; CHECK: .long foo
; CHECK: [[BAR_LBL:\.LCP[0-9A-Za-z_]+]]:
; CHECK: .long bar

define i32 @test() {
  %1 = load i32, i32* @foo, align 4

  ; CHECK: load_32 [[FOO_PTR:s[0-9]+]], [[FOO_LBL]]
  ; CHECK: load_32 [[TMP_REG:s[0-9]+]], ([[FOO_PTR]])

  store i32 %1, i32* @bar, align 4

  ; CHECK: load_32 [[BAR_PTR:s[0-9]+]], [[BAR_LBL]]
  ; CHECK: store_32 [[TMP_REG]], ([[BAR_PTR]])

  ret i32 %1
}
