; RUN: llc %s -o - | FileCheck %s
;
; Floating point absolute value. There isn't a native instruction to do this,
; so it will be lowered to integer and to mask the sign bit.
;

target triple = "nyuzi-elf-none"

declare float @llvm.fabs.f32(float)

; CHECK: .LCPI0_0:
; CHECK:	.long	2147483647

define float @test(float %foo) {
  %call = call float @llvm.fabs.f32(float  %foo)

  ; CHECK: load_32 s1, .LCPI0_0
  ; CHECK-NEXT: and s0, s0, s1
  ; CHECK-NEXT: ret

  ret float %call
}
