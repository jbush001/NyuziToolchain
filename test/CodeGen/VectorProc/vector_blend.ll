; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

declare <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %a, <16 x i32> %b)
declare <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %a, <16 x float> %b)

; Vector op vector masked
define <16 x i32> @test_vvm(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test_vvm
	%sum = add <16 x i32> %a, %b
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.mask v0, s0, v0, v1

	ret <16 x i32> %c
}

; Vector op immediate, masked
define <16 x i32> @test_vim(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test_vim
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.mask v0, s0, v0, 48

	ret <16 x i32> %c
}

; vector = scalar op immediate, integer, masked
define <16 x i32> @test_sim(i32 %mask, i32 %a, <16 x i32> %b) {	; CHECK: test_sim:
	%single = insertelement <16 x i32> undef, i32 %a, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %splat, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %b)

	; CHECK: add.i.mask v0, s0, s1, 48

	ret <16 x i32> %c
}

; vector = vector op vector, float, masked
define <16 x float> @vvm_f(i32 %mask, <16 x float> %a, <16 x float> %b) { ; CHECK: vvm_f
	%sum = fadd <16 x float> %a, %b
	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.mask v0, s0, v0, v1

	ret <16 x float> %c
}

; vector = vector op scalar, float, masked
define <16 x float> @vsm_f(i32 %mask, <16 x float> %a, float %b) { ; CHECK: vsm_f
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat

	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.mask v0, s0, v0, s1

	ret <16 x float> %c
}



