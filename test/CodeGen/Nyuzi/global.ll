; RUN: llc %s -o - | FileCheck %s
;
; Test global variable accesses
;

target triple = "nyuzi-elf-none"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

define i32 @test() {
  %1 = load i32, i32* @foo, align 4
  store i32 %1, i32* @bar, align 4

  ; CHECK: movehi s0, hi(bar)
  ; CHECK: or s1, s0, lo(bar)
  ; CHECK: movehi s0, hi(foo)
  ; CHECK: or s0, s0, lo(foo)
  ; CHECK: load_32 s0, (s0)
  ; CHECK: store_32 s0, (s1)

  ret i32 %1
}
