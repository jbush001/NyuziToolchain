; RUN: llc %s -o - | FileCheck %s
;
; Regression test for issue #54. The return type from uitofp was incorrect.

target triple = "nyuzi-elf-none"

define <16 x i32> @fail() {
  %a = uitofp <16 x i1> undef to <16 x float>
  %b = bitcast <16 x float> %a to <16 x i32>

  ; CHECK-DAG: movehi [[A:s[0-9]+]], hi(.LCPI0_0)
  ; CHECK-DAG: or [[B:s[0-9]+]], [[A]], lo(.LCPI0_0)

  ; CHECK-DAG: movehi [[C:s[0-9]+]], hi(.LCPI0_1)
  ; CHECK-DAG: or [[D:s[0-9]+]], [[C]], lo(.LCPI0_1)

  ; CHECK-DAG: load_32 [[E:s[0-9]+]], ([[B]])
  ; CHECK-DAG: load_32 [[F:s[0-9]+]], ([[D]])

  ; CHECK-DAG: move [[G:v[0-9]+]], [[E]]
  ; CHECK-DAG: move_mask v0, [[E]], [[F]]

  ret <16 x i32> %b
}