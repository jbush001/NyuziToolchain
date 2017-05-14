; RUN: llc %s -o - | FileCheck %s
;
; Floating point <-> integer conversion tests
;

target triple = "nyuzi-elf-none"

define i32 @test_fptosi_ss(float %a) { ; CHECK-LABEL: test_fptosi_ss:
  %1 = fptosi float %a to i32

  ; CHECK: ftoi s0, s0

  ret i32 %1
}

define <16 x i32> @test_fptosi_vs(float %a) { ; CHECK-LABEL: test_fptosi_vs:
  %single = insertelement <16 x float> undef, float %a, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer
  %1 = fptosi <16 x float> %splat to <16 x i32>

  ; CHECK: ftoi v0, s0

  ret <16 x i32> %1
}

define <16 x i32> @test_fptosi_vsm(float %a, <16 x i1> %mask) { ; CHECK-LABEL: test_fptosi_vsm:
  %single = insertelement <16 x float> undef, float %a, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer
  %1 = fptosi <16 x float> %splat to <16 x i32>
  %2 = bitcast <16 x float> %splat to <16 x i32>
  %3 = select <16 x i1> %mask, <16 x i32> %1, <16 x i32> %2

  ; CHECK: ftoi_mask v0, s1, s0

  ret <16 x i32> %3
}

define <16 x i32> @test_fptosi_vv(<16 x float> %a) { ; CHECK-LABEL: test_fptosi_vv:
  %1 = fptosi <16 x float> %a to <16 x i32>

  ; CHECK: ftoi v0, v0

  ret <16 x i32> %1
}

define <16 x i32> @test_fptosi_vvm(<16 x float> %a, <16 x i1> %mask) { ; CHECK-LABEL: test_fptosi_vvm:
  %1 = fptosi <16 x float> %a to <16 x i32>
  %2 = bitcast <16 x float> %a to <16 x i32>
  %3 = select <16 x i1> %mask, <16 x i32> %1, <16 x i32> %2

  ; CHECK: ftoi_mask v0, s0, v0

  ret <16 x i32> %3
}

define float @test_sitofp_ss(i32 %a) { ; CHECK-LABEL: test_sitofp_ss:
  %1 = sitofp i32 %a to float

  ; The check not here ensures this doesn't try to generate an unsigned
  ; version of the conversion (emulated by lowering code)
  ; CHECK-NOT: cmplt_i
  ; CHECK: itof s0, s0
  ; CHECK-NOT: add_f

  ret float %1
}

define <16 x float> @test_sitofp_vs(i32 %a) { ; CHECK-LABEL: test_sitofp_vs:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %1 = sitofp <16 x i32> %splat to <16 x float>

  ; CHECK-NOT: cmplt_i
  ; CHECK: itof v0, s0
  ; CHECK-NOT: add_f

  ret <16 x float> %1
}

define <16 x float> @test_sitofp_vsm(i32 %a, <16 x i1> %mask) { ; CHECK-LABEL: test_sitofp_vsm:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %1 = sitofp <16 x i32> %splat to <16 x float>
  %2 = bitcast <16 x i32> %splat to <16 x float>
  %3 = select <16 x i1> %mask, <16 x float> %1, <16 x float> %2

  ; CHECK-NOT: cmplt_i
  ; CHECK: itof_mask v0, s1, s0
  ; CHECK-NOT: add_f

  ret <16 x float> %3
}

define <16 x float> @test_sitofp_vv(<16 x i32> %a) { ; CHECK-LABEL: test_sitofp_vv:
  %1 = sitofp <16 x i32> %a to <16 x float>

  ; CHECK-NOT: cmplt_i
  ; CHECK: itof v0, v0
  ; CHECK-NOT: add_f

  ret <16 x float> %1
}

define <16 x float> @test_sitofp_vvm(<16 x i32> %a, <16 x i1> %mask) { ; CHECK-LABEL: test_sitofp_vvm:
  %1 = sitofp <16 x i32> %a to <16 x float>
  %2 = bitcast <16 x i32> %a to <16 x float>
  %3 = select <16 x i1> %mask, <16 x float> %1, <16 x float> %2

  ; CHECK-NOT: cmplt_i
  ; CHECK: itof_mask v0, s0, v0
  ; CHECK-NOT: add_f

  ret <16 x float> %3
}

; The native itof instruction is signed. We emulate unsigned by checking for
; wrap and adjusting.

define float @test_uitofp_ss(i32 %a) { ; CHECK-LABEL: test_uitofp_ss:
  %1 = uitofp i32 %a to float

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, 0
  ; CHECK: itof s{{[0-9]+}}, s{{[0-9]+}}
  ; CHECK: add_f s{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}

  ret float %1
}

define <16 x float> @test_uitofp_vs(i32 %a) { ; CHECK-LABEL: test_uitofp_vs:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %1 = uitofp <16 x i32> %splat to <16 x float>

  ; CHECK: itof
  ; CHECK: add_f v

  ret <16 x float> %1
}

define <16 x float> @test_uitofp_vsm(i32 %a, <16 x i1> %mask) { ; CHECK-LABEL: test_uitofp_vsm:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer
  %1 = uitofp <16 x i32> %splat to <16 x float>
  %2 = bitcast <16 x i32> %splat to <16 x float>
  %3 = select <16 x i1> %mask, <16 x float> %1, <16 x float> %2

  ; CHECK: itof
  ; CHECK: add_f_mask v

  ret <16 x float> %3
}

define <16 x float> @test_uitofp_vv(<16 x i32> %a) { ; CHECK-LABEL: test_uitofp_vv:
  %1 = uitofp <16 x i32> %a to <16 x float>

  ; CHECK: itof v{{[0-9]+}}, v{{[0-9]+}}
  ; CHECK: add_f v

  ret <16 x float> %1
}

define <16 x float> @test_uitofp_vvm(<16 x i32> %a, <16 x i1> %mask) { ; CHECK-LABEL: test_uitofp_vvm:
  %1 = uitofp <16 x i32> %a to <16 x float>
  %2 = bitcast <16 x i32> %a to <16 x float>
  %3 = select <16 x i1> %mask, <16 x float> %1, <16 x float> %2

  ; CHECK: itof v
  ; CHECK: add_f_mask v

  ret <16 x float> %3
}

; This form with a constant will attempt to replace the result with a constant.
; This is a regression test. Previously, there was a bug in NyuziTargetLowering::LowerSINT_TO_FP
; where the return type of the conversion was wrong and would assert.
define <16 x float> @test_const_smtofv(<16 x i1> %mask) { ; CHECK-LABEL: test_const_smtofv
  %res = uitofp <16 x i1> <i1 1, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef, i1 undef> to <16 x float>

  ; CHECK: move v0, s0

  ret <16 x float> %res
}



