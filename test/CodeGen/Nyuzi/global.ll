; RUN: llc %s -o - | FileCheck %s -check-prefix=CHECK-STATIC
; RUN: llc -relocation-model=pic %s -o - | FileCheck %s -check-prefix=CHECK-PIC
;
;
; Test global variable accesses
;

target triple = "nyuzi-elf-none"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

define i32 @test() {
  %1 = load i32, i32* @foo, align 4
  store i32 %1, i32* @bar, align 4

  ; CHECK-STATIC-DAG: movehi [[SRC1:s[0-9]+]], hi(foo)
  ; CHECK-STATIC-DAG: or [[SRC2:s[0-9]+]], [[SRC1]], lo(foo)
  ; CHECK-STATIC-DAG: load_32 [[VALUE:s[0-9]+]], ([[SRC2]])
  ; CHECK-STATIC-DAG: movehi [[DST1:s[0-9]+]], hi(bar)
  ; CHECK-STATIC-DAG: or [[DST2:s[0-9]+]], [[DST1]], lo(bar)
  ; CHECK-STATIC-DAG: store_32 [[VALUE]], ([[DST2]])

  ; CHECK-PIC: load_32 [[PTR1:s[0-9]+]], got(foo)(gp)
  ; CHECK-PIC: load_32 s{{[0-9+]}}, ([[PTR1]])
  ; CHECK-PIC: load_32 [[PTR2:s[0-9]+]], got(bar)(gp)
  ; CHECK-PIC: store_32 s{{[0-9+]}}, ([[PTR1:s[0-9]+]])

  ret i32 %1
}
