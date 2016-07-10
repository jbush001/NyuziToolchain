; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

declare float @llvm.fabs.f32(float)

define float @test(float %foo) {
  %call = call float @llvm.fabs.f32(float  %foo)

  ; CHECK: and

  ret float %call
}
