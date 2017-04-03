; RUN: llc %s -o - | FileCheck %s
;
; This test validates ALU operations on v16i1.

target triple = "nyuzi"

define <16 x i1> @frobincate(<16 x i1>, <16 x i1>, <16 x i1>) { ; CHECK-LABEL: frobincate:
entry:
  %xor = xor <16 x i1> %0, %1
  %and = and <16 x i1> %xor, %2
  %bit5 = insertelement <16 x i1> zeroinitializer, i1 true, i32 5
  %or = or <16 x i1> %and, %bit5

  ; CHECK: xor s0, s0, s1
  ; CHECK: and s0, s0, s2
  ; CHECK: or s0, s0, 32

  ret <16 x i1> %or
}
