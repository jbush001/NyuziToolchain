; RUN: llc -relocation-model=pic %s -o - | FileCheck %s
;
; Test global variable accesses
;

target triple = "nyuzi-elf-none"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

define i32 @test() {
  %1 = load i32, i32* @foo, align 4
  store i32 %1, i32* @bar, align 4

  ; CHECK: load_32 [[PTR1:s[0-9]+]], got(foo)(gp)
  ; CHECK: load_32 s{{[0-9+]}}, ([[PTR1]])
  ; CHECK: load_32 [[PTR2:s[0-9]+]], got(bar)(gp)
  ; CHECK: store_32 s{{[0-9+]}}, ([[PTR1:s[0-9]+]])

  ret i32 %1
}
