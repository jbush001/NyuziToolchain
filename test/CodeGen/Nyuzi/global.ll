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

  ; CHECK-DAG: movehi [[SRC1:s[0-9]+]], hi(foo)
  ; CHECK-DAG: or [[SRC2:s[0-9]+]], [[SRC1]], lo(foo)
  ; CHECK-DAG: load_32 [[VALUE:s[0-9]+]], ([[SRC2]])
  ; CHECK-DAG: movehi [[DST1:s[0-9]+]], hi(bar)
  ; CHECK-DAG: or [[DST2:s[0-9]+]], [[DST1]], lo(bar)
  ; CHECK-DAG: store_32 [[VALUE]], ([[DST2]])

  ret i32 %1
}
