; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi-none-none"

; Verify SETO and SETUO nodes are generated correctly.
; Regression test for issue #49

define <16 x i1> @isnan(<16 x float> %a) { ; CHECK-LABEL: isnan:
BB:
  ; Unordered comparison is always false if either operand is NaN, so this
  ; will return true only if %a is NaN. This will get converted to a
  ; SETUO node.
  %res = fcmp une <16 x float> %a, %a

  ; CHECK: cmpeq_f s1, v0, v0
  ; CHECK: xor s0, s1, s0

  ret <16 x i1> %res
}

define <16 x i1> @isnotnan(<16 x float> %a) { ; CHECK-LABEL: isnotnan:
BB:
  ; Inverse of above. Will get converted to a SETO node.
  %res = fcmp oeq <16 x float> %a, %a

  ; CHECK: cmpeq_f s0, v0, v0
  ; CHECK-NOT: xor

  ret <16 x i1> %res
}
