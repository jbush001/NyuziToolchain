; RUN: llc %s -o - | FileCheck %s
;
; Regression test, bug found during randomized testing
; Vector SETCC that doesn't expand to v16i32, but uses the result immediately.
;

target triple = "nyuzi-none-none"

define <16 x i1> @setcc_shuffle() {
  %comp = icmp slt <16 x i1> undef, zeroinitializer
  %result = shufflevector <16 x i1> %comp, <16 x i1> undef, <16 x i32> <i32 undef, i32 8, i32 10, i32 12, i32 14, i32 undef, i32 18, i32 20, i32 22, i32 24, i32 26, i32 28, i32 30, i32 0, i32 undef, i32 4>
  ret <16 x i1> %result

  ; CHECK: cmplt_i s0, v0, 0
	; CHECK: move v0, 0
	; CHECK: move_mask v0, s0, -1
}
