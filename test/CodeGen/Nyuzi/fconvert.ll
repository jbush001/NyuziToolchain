; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

; Floating point conversion tests

define float @test_sitofp(i32 %a) {  ; CHECK: test_sitofp:
  %conv = sitofp i32 %a to float

  ; CHECK: itof

  ret float %conv
}

define i32 @test_sftoip(float %a) { ; CHECK: test_sftoip:
  %conv = fptosi float %a to i32

  ; CHECK: ftoi

  ret i32 %conv
}

define <16 x float> @test_sitofpv(<16 x i32> %a) {  ; CHECK: test_sitofpv:
  %conv = sitofp <16 x i32> %a to <16 x float>

  ; CHECK: itof

  ret <16 x float> %conv
}

define <16 x i32> @test_sftoipv(<16 x float> %a) { ; CHECK: test_sftoipv:
  %conv = fptosi <16 x float> %a to <16 x i32>

  ; CHECK: ftoi

  ret <16 x i32> %conv
}

define <16 x float> @test_sitofpvs(i32 %a) {  ; CHECK: test_sitofpvs:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %conv = sitofp <16 x i32> %splat to <16 x float>

  ; CHECK: itof v{{[0-9]+}}, s{{[0-9]+}}

  ret <16 x float> %conv
}

define <16 x i32> @test_sftoipvs(float %a) {  ; CHECK: test_sftoipvs:
  %single = insertelement <16 x float> undef, float %a, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer
  %conv = fptosi <16 x float> %splat to <16 x i32>

  ; CHECK: ftoi v{{[0-9]+}}, s{{[0-9]+}}

  ret <16 x i32> %conv
}
