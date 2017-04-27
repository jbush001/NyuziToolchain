; RUN: llc %s -o - | FileCheck %s
;
; Test inserting a scalar element into a vector lane using insertlement
; instruction
;

target triple = "nyuzi-elf-none"

define <16 x i32> @test_inserti(<16 x i32> %orig, i32 %value, i32 %lane) {	; CHECK-LABEL: test_inserti:
  %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane

  ; Load 1, shift it to select the appropriate lane, and do a predicated
  ; vector move.

  ; CHECK: move s2, 1
  ; CHECK: shl [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x i32> %result
}

define <16 x i32> @test_inserti_const(<16 x i32> %orig, i32 %value) {	; CHECK-LABEL: test_inserti_const:
  %result = insertelement <16 x i32> %orig, i32 %value, i32 7

  ; Lane is constant, so the mask should be constant folded.

  ; CHECK: move [[MASKREG:s[0-9]+]], 128
	; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x i32> %result
}

define <16 x float> @test_insertf(<16 x float> %orig, float %value, i32 %lane) { ; CHECK-LABEL: test_insertf:
  %result = insertelement <16 x float> %orig, float %value, i32 %lane

  ; CHECK: move s2, 1
  ; CHECK: shl [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x float> %result
}

; If insertelement is called with an undef vector, we just convert it to a splat.

define <16 x i32> @test_insert_undef(i32 %a) {  ; CHECK-LABEL: test_insert_undef:
  %result = insertelement <16 x i32> undef, i32 %a, i32 0

  ; CHECK: move v0, s0

  ret <16 x i32> %result
}

; v16i1 insertions require bit manipulation
define <16 x i1> @test_v16i1_insert(<16 x i1> %orig, i1 %a) { ; CHECK-LABEL: test_v16i1_insert
  %result = insertelement <16 x i1> %orig, i1 %a, i32 6

  ; CHECK: and s1, s1, 1
  ; CHECK: and s0, s0, -65
  ; CHECK: shl s1, s1, 6
  ; CHECK: or s0, s1, s0

  ret <16 x i1> %result
}
