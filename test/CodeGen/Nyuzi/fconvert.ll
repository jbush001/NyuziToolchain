; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

; Floating point conversion tests

define float @test_sitofp(i32 %a) { ; CHECK-LABEL: test_sitofp:
  %conv = sitofp i32 %a to float

  ; CHECK: itof

  ret float %conv
}

; The native itof instruction is signed. We emulate unsigned by checking for
; wrap and adjusting.
define float @test_uitofp(i32 %a) { ; CHECK-LABEL: test_uitofp:
  %conv = uitofp i32 %a to float

  ; CHECK: itof [[CONV:s[0-9]+]], [[SRCVAL:s[0-9]+]]
	; CHECK: cmplt_i [[CMPVAL:s[0-9]+]], [[SRCVAL]], 0
	; CHECK: btrue [[CMPVAL]],
	; CHECK: add_f s{{[0-9]+}}, [[CONV]],

  ret float %conv
}

define i32 @test_sftoip(float %a) { ; CHECK-LABEL: test_sftoip:
  %conv = fptosi float %a to i32

  ; CHECK: ftoi

  ret i32 %conv
}

define <16 x float> @test_sitofpv(<16 x i32> %a) { ; CHECK-LABEL: test_sitofpv:
  %conv = sitofp <16 x i32> %a to <16 x float>

  ; CHECK: itof

  ret <16 x float> %conv
}

; This must adjust signed results like uitofp, but does it with a predicated
; instruction because it's working on vectors.
define <16 x float> @test_uitofpv(<16 x i32> %a) { ; CHECK-LABEL: test_uitofpv:
  %conv = uitofp <16 x i32> %a to <16 x float>

  ; CHECK: itof [[CONV:v[0-9]+]], [[SRCVAL:v[0-9]+]]
	; CHECK: cmplt_i [[CMPVAL:s[0-9]+]], [[SRCVAL]], 0
	; CHECK: add_f_mask v{{[0-9]+}}, [[CMPVAL]], [[CONV]],

  ret <16 x float> %conv
}

define <16 x i32> @test_sftoipv(<16 x float> %a) { ; CHECK-LABEL: test_sftoipv:
  %conv = fptosi <16 x float> %a to <16 x i32>

  ; CHECK: ftoi

  ret <16 x i32> %conv
}

define <16 x float> @test_sitofpvs(i32 %a) { ; CHECK-LABEL: test_sitofpvs:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %conv = sitofp <16 x i32> %splat to <16 x float>

  ; CHECK: itof v{{[0-9]+}}, s{{[0-9]+}}

  ret <16 x float> %conv
}

define <16 x i32> @test_sftoipvs(float %a) { ; CHECK-LABEL: test_sftoipvs:
  %single = insertelement <16 x float> undef, float %a, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer
  %conv = fptosi <16 x float> %splat to <16 x i32>

  ; CHECK: ftoi v{{[0-9]+}}, s{{[0-9]+}}

  ret <16 x i32> %conv
}
