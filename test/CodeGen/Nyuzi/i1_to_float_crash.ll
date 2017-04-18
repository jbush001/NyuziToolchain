; RUN: llc %s -o - | FileCheck %s
;
; Regression test for issue #54. The return type from uitofp was incorrect.

target triple = "nyuzi-elf-none"

define <16 x i32> @fail() {
  %a = uitofp <16 x i1> undef to <16 x float>
  %b = bitcast <16 x float> %a to <16 x i32>

  ; CHECK: movehi s0, hi(.LCPI0_0)
  ; CHECK: or s0, s0, lo(.LCPI0_0)
  ; CHECK: load_32 s0, (s0)
  ; CHECK: movehi s1, hi(.LCPI0_1)
  ; CHECK: or s1, s1, lo(.LCPI0_1)
  ; CHECK: load_32 s1, (s1)
  ; CHECK: move v0, s1
  ; CHECK: move_mask v0, s0, s0

  ret <16 x i32> %b
}