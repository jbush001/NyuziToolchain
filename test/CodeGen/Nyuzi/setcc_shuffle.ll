; RUN: llc %s -o - | FileCheck %s
;
; Regression test, bug found during randomized testing
; Vector SETCC that doesn't expand to v16i32, but uses the result immediately.
;

target triple = "nyuzi-none-none"

define <16 x i1> @setcc_shuffle(<16 x i1> %a) {
  %comp = icmp slt <16 x i1> %a, zeroinitializer
  %result = shufflevector <16 x i1> %comp, <16 x i1> undef, <16 x i32> <i32 undef, i32 8, i32 10, i32 12, i32 14, i32 undef, i32 18, i32 20, i32 22, i32 24, i32 26, i32 28, i32 30, i32 0, i32 undef, i32 4>
  ret <16 x i1> %result

  ; CHECK-DAG: move v{{[0-9]+}}, 0
  ; CHECK-DAG: load_v v{{[0-9]+}},
  ; CHECK: shuffle v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}
  ; CHECK: and v{{[0-9]+}}, v{{[0-9]+}}, 1
  ; CHECK: cmpeq_i s0, v{{[0-9]+}}, 1
}
