; Floating point conversion 
; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

declare float @llvm.fabs.f32(float)

define float @test(float %foo) {
  %call = call float @llvm.fabs.f32(float  %foo)

	; CHECK: and
  ret float %call
}


