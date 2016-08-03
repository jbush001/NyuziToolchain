; RUN: llc %s -o - | FileCheck %s
;
; Floating point division test.
; This architecture doesn't have a native divide instruction, so it uses an
; instruction to compute the initial estimate (with less precision) and two
; Newton-Raphson iterations.
;

target triple = "nyuzi-elf-none"

define float @divide_float(float %a, float %b) { 	; CHECK-LABEL: divide_float:
  %1 = fdiv float %a, %b

  ; CHECK: reciprocal [[ESTIMATE1:s[0-9]+]], [[DENOMINATOR:s[0-9]+]]

  ; Iteration 1
  ; CHECK: mul_f [[TRIAL1:s[0-9]+]], [[ESTIMATE1]], [[DENOMINATOR]]
  ; CHECK: sub_f [[ERROR1:s[0-9]+]], [[TWO:s[0-9]+]], [[TRIAL1]]
  ; CHECK: mul_f [[ESTIMATE2:s[0-9]+]], [[ESTIMATE1]], [[ERROR1]]

  ; Iteration 2
  ; CHECK: mul_f [[TRIAL2:s[0-9]+]], [[ESTIMATE2]], [[DENOMINATOR]]
  ; CHECK: sub_f [[ERROR2:s[0-9]+]], [[TWO]], [[TRIAL2]]
  ; CHECK: mul_f [[ESTIMATE3:s[0-9]+]], [[ESTIMATE2]], [[ERROR2]]

  ; Multiply recriprocal by dividend to compute result
  ; CHECK: mul_f {{s[0-9]+}}, {{s[0-9]+}}, [[ESTIMATE3]]

  ret float %1
}

;
; There is a special case to for 1.0/f. It skips the last multiplication
;
define float @reciprocal_float(float %b) { 	; CHECK-LABEL: reciprocal_float:
  %1 = fdiv float 1.0, %b

  ; CHECK: reciprocal [[ESTIMATE1:s[0-9]+]], [[DENOMINATOR:s[0-9]+]]

  ; Iteration 1
  ; CHECK: mul_f [[TRIAL1:s[0-9]+]], [[ESTIMATE1]], [[DENOMINATOR]]
  ; CHECK: sub_f [[ERROR1:s[0-9]+]], [[TWO:s[0-9]+]], [[TRIAL1]]
  ; CHECK: mul_f [[ESTIMATE2:s[0-9]+]], [[ESTIMATE1]], [[ERROR1]]

  ; Iteration 2
  ; CHECK: mul_f [[TRIAL2:s[0-9]+]], [[ESTIMATE2]], [[DENOMINATOR]]
  ; CHECK: sub_f [[ERROR2:s[0-9]+]], [[TWO]], [[TRIAL2]]
  ; CHECK: mul_f [[ESTIMATE3:s[0-9]+]], [[ESTIMATE2]], [[ERROR2]]
  ; CHECK-NOT: mul_f
  ; CHECK: ret

  ret float %1
}
