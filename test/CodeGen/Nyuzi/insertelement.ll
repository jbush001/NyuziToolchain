; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

define <16 x i32> @inserti(<16 x i32> %orig, i32 %value, i32 %lane) {	; CHECK-LABEL: inserti:
  %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane

  ; Load 0x8000, shift it to select the appropriate lane, and do a predicated
  ; vector move.

  ; CHECK: load_32 s2, .LCPI
  ; CHECK: shr [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x i32> %result
}

define <16 x float> @insertf(<16 x float> %orig, float %value, i32 %lane) { ; CHECK-LABEL: insertf:
  %result = insertelement <16 x float> %orig, float %value, i32 %lane

  ; CHECK: load_32 s2, .LCPI
  ; CHECK: shr [[MASKREG:s[0-9]+]], s2, s1
  ; CHECK: move_mask v0, [[MASKREG]], s0

  ret <16 x float> %result
}
