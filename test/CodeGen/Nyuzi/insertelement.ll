; RUN: llc %s -o - | FileCheck %s
;
; Test inserting a scalar element into a vector lane using insertlement
; instruction
;

target triple = "nyuzi-elf-none"

define <16 x i32> @test_inserti(<16 x i32> %orig, i32 %value, i32 %lane) {	; CHECK-LABEL: test_inserti:
  %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane

  ; Load 0x8000, shift it to select the appropriate lane, and do a predicated
  ; vector move.

  ; CHECK: load_32 s2, .LCPI
  ; CHECK: shr [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x i32> %result
}

define <16 x float> @test_insertf(<16 x float> %orig, float %value, i32 %lane) { ; CHECK-LABEL: test_insertf:
  %result = insertelement <16 x float> %orig, float %value, i32 %lane

  ; CHECK: load_32 s2, .LCPI
  ; CHECK: shr [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x float> %result
}

; If insertelement is called with an undef vector, we just convert it to a splat.

define <16 x i32> @test_insert_undef(i32 %a) {  ; CHECK-LABEL: test_insert_undef:
  %result = insertelement <16 x i32> undef, i32 %a, i32 0

  ; CHECK: move v0, s0

  ret <16 x i32> %result
}
