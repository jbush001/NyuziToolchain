; RUN: llc %s -o - | FileCheck %s
;
; Instructions that need to generate library calls because they aren't
; supported in hardware.
;

declare float @llvm.sqrt.f32(float %Val)
declare float @llvm.sin.f32(float %Val)
declare float @llvm.cos.f32(float %Val)

define i32 @call_udiv(i32 %a, i32 %b) { ; CHECK-LABEL: call_udiv:
  %result = udiv i32 %a, %b

  ; CHECK: call __udivsi3

  ret i32 %result
}

define <16 x i32> @call_udivv(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: call_udivv:
  %result = udiv <16 x i32> %a, %b

  ; Expands to performing scalar call for each lane
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3
  ; CHECK: getlane
  ; CHECK: call __udivsi3

  ret <16 x i32> %result
}

define i32 @call_urem(i32 %ptr, i32 %a, i32 %b) { ; CHECK-LABEL: call_urem:
  %result = urem i32 %a, %b

  ; CHECK: call __umodsi3

  ret i32 %result
}

define <16 x i32> @call_uremv(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: call_uremv:
  %result = urem <16 x i32> %a, %b

  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3
  ; CHECK: call __umodsi3

  ret <16 x i32> %result
}

define i32 @call_sdiv(i32 %a, i32 %b) { ; CHECK-LABEL: call_sdiv:
  %result = sdiv i32 %a, %b

  ; CHECK: call __divsi3

  ret i32 %result
}

define <16 x i32> @call_sdivv(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: call_sdivv:
  %result = sdiv <16 x i32> %a, %b

  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3
  ; CHECK: call __divsi3

  ret <16 x i32> %result
}

define i32 @call_srem(i32 %a, i32 %b) { ; CHECK-LABEL: call_srem:
  %result = srem i32 %a, %b

  ; CHECK: call __modsi3

  ret i32 %result
}

define <16 x i32> @call_sremv(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: call_sremv:
  %result = srem <16 x i32> %a, %b

  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3
  ; CHECK: call __modsi3

  ret <16 x i32> %result
}

define float @call_sqrtf(float %a) { ; CHECK-LABEL: call_sqrtf:
  %result = call float @llvm.sqrt.f32(float %a)

  ; CHECK: call sqrtf

  ret float %result
}

define float @call_sinf(float %a) { ; CHECK-LABEL: call_sinf
  %result = call float @llvm.sin.f32(float %a)

  ; CHECK: call sinf

  ret float %result
}

define float @call_cosf(float %a) { ; CHECK-LABEL: call_cosf
  %result = call float @llvm.cos.f32(float %a)

  ; CHECK: call cosf

  ret float %result
}

define float @call_remf(float %a, float %b) { ; CHECK-LABEL: call_remf
  %result = frem float %a, %b

  ; CHECK: call fmodf

  ret float %result
}

define <16 x float> @call_remfv(<16 x float> %a, <16 x float> %b) { ; CHECK-LABEL: call_remfv
  %result = frem <16 x float> %a, %b

  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf
  ; CHECK: call fmodf


  ret <16 x float> %result
}

; XXX how to generate sincos?
