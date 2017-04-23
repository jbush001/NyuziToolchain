; RUN: llc %s -o - | FileCheck %s
;
; Floating point <-> integer conversion tests
;

target triple = "nyuzi-elf-none"

define float @test_sitofp(i32 %a) { ; CHECK-LABEL: test_sitofp:
  %conv = sitofp i32 %a to float

  ; CHECK: itof

  ret float %conv
}

; The native itof instruction is signed. We emulate unsigned by checking for
; wrap and adjusting.
define float @test_uitofp(i32 %a) { ; CHECK-LABEL: test_uitofp:
  %conv = uitofp i32 %a to float

  ; CHECK: cmplt_i s{{[0-9]+}}, s{{[0-9]+}}, 0
  ; CHECK: itof s{{[0-9]+}}, s{{[0-9]+}}
  ; CHECK: add_f s{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}

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

; This must adjust signed results like uitofp, but expands differently.
define <16 x float> @test_uitofpv(<16 x i32> %a) { ; CHECK-LABEL: test_uitofpv:
  %conv = uitofp <16 x i32> %a to <16 x float>

  ; CHECK: itof v{{[0-9]+}}, v{{[0-9]+}}

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

define <16 x float> @test_umtofv(<16 x i1> %mask) { ; CHECK-LABEL: test_umtofv
  %res = uitofp <16 x i1> %mask to <16 x float>

  ; CHECK: move_mask v0, s0

  ret <16 x float> %res
}

define <16 x float> @test_smtofv(<16 x i1> %mask) { ; CHECK-LABEL: test_smtofv
  %res = sitofp <16 x i1> %mask to <16 x float>

  ; CHECK: move_mask v0, s0

  ret <16 x float> %res
}

; This form with a constant will attempt to replace the result with a constant.
; This is a regression test. Previously, there was a bug in NyuziTargetLowering::LowerSINT_TO_F
; where the return type of the conversion was wrong and would assert.
define <16 x float> @test_const_smtofv(<16 x i1> %mask) { ; CHECK-LABEL: test_const_smtofv
  %res = sitofp <16 x i1> <i1 1, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef> to <16 x float>

  ; CHECK: move v0, s0

  ret <16 x float> %res
}

define <16 x i1> @test_ftosmv(<16 x float> %val) { ; CHECK-LABEL: test_ftosmv:
  %res = fptosi <16 x float> %val to <16 x i1>

  ; CHECK: cmpne_f s0, v0, s

  ret <16 x i1> %res
}

define <16 x i1> @test_ftoumv(<16 x float> %val) { ; CHECK-LABEL: test_ftoumv:
  %res = fptoui <16 x float> %val to <16 x i1>

  ; CHECK: cmpne_f s0, v0, s

  ret <16 x i1> %res
}


