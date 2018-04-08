; RUN: llc %s -o - | FileCheck %s
; Regression test: this crash occurred when upgrading to upstream SVN
; version 329504. This will be converted to an FTRUNC SDNode.

target triple = "nyuzi-none-none"

define <16 x float> @my_ftrunc(<16 x float> %in) {
  %a = fptosi <16 x float> %in to <16 x i32>    ; CHECK: ftoi v0, v0
  %b = sitofp <16 x i32> %a to <16 x float>     ; CHECK: itof v0, v0
  ret <16 x float> %b  ; CHECK: ret
}
