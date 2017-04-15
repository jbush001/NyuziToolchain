; RUN: llc %s -o - | FileCheck %s
;
; Floating point absolute value. There isn't a native instruction to do this,
; so it will be lowered to integer and to mask the sign bit.
;

target triple = "nyuzi-elf-none"

declare float @llvm.fabs.f32(float)

define float @test(float %foo) {
  %call = call float @llvm.fabs.f32(float  %foo)

	; CHECK: movehi [[TMP1:s[0-9]+]], 262143
	; CHECK-NEXT: or [[TMP2:s[0-9]+]], [[TMP1]], 8191
  ; CHECK-NEXT: and s0, s0, [[TMP2]]
  ; CHECK-NEXT: ret

  ret float %call
}
