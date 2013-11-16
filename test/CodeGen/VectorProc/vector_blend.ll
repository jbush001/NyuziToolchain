; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

declare <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %a, <16 x i32> %b)
declare <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %a, <16 x float> %b)
declare <16 x i32> @llvm.ctlz.v16i32(<16 x i32> %src, i1 %zero_undef)
declare <16 x i32> @llvm.vectorproc.__builtin_vp_shufflei(<16 x i32> %a, <16 x i32> %b)

; Format A, Vector op vector masked
define <16 x i32> @test1(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test1
	%sum = add <16 x i32> %a, %b
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.mask v0, s0, v0, v1

	ret <16 x i32> %c
}

; Format A, Vector op vector, invert mask
define <16 x i32> @test2(i32 %mask, <16 x i32> %a, <16 x i32> %b) { ; CHECK: test2
	%sum = add <16 x i32> %a, %b
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.invmask v0, s0, v0, v1

	ret <16 x i32> %c
}

; Format A, Vector op scalar masked
define <16 x i32> @test3(i32 %mask, <16 x i32> %a, i32 %b) {	; CHECK: test3
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %a, %splat
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.mask v0, s0, v0, s1

	ret <16 x i32> %c
}

; Format A, Vector op scalar, invert masked
define <16 x i32> @test4(i32 %mask, <16 x i32> %a, i32 %b) {	; CHECK: test4
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %a, %splat
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.invmask v0, s0, v0, s1

	ret <16 x i32> %c
}

; Format B, Vector op immediate, mask
define <16 x i32> @test5(i32 %mask, <16 x i32> %a, <16 x i32> %b) { ; CHECK: test5
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.mask v0, s0, v0, 48

	ret <16 x i32> %c
}

; Format B, Vector op immediate, invert mask
define <16 x i32> @test6(i32 %mask, <16 x i32> %a, <16 x i32> %b) { ; CHECK: test6
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %sum, <16 x i32> %a)

	; CHECK: add.i.invmask v0, s0, v0, 48

	ret <16 x i32> %c
}

; Format B, vector = scalar op immediate, masked
define <16 x i32> @test7(i32 %mask, i32 %a, <16 x i32> %b) {	; CHECK: test7:
	%single = insertelement <16 x i32> undef, i32 %a, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %splat, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %sum, <16 x i32> %b)

	; CHECK: add.i.mask v0, s0, s1, 48

	ret <16 x i32> %c
}

; Format B, vector = scalar op immediate, invert mask
define <16 x i32> @test8(i32 %mask, i32 %a, <16 x i32> %b) {	; CHECK: test8:
	%single = insertelement <16 x i32> undef, i32 %a, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %splat, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %sum, <16 x i32> %b)

	; CHECK: add.i.invmask v0, s0, s1, 48

	ret <16 x i32> %c
}

; vector = vector op vector, float, masked
define <16 x float> @test9(i32 %mask, <16 x float> %a, <16 x float> %b) { ; CHECK: test9
	%sum = fadd <16 x float> %a, %b
	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.mask v0, s0, v0, v1

	ret <16 x float> %c
}

; vector = vector op vector, float, invert mask
define <16 x float> @test10(i32 %mask, <16 x float> %a, <16 x float> %b) { ; CHECK: test10
	%sum = fadd <16 x float> %a, %b
	%notmask = xor i32 %mask, -1
	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %notmask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.invmask v0, s0, v0, v1

	ret <16 x float> %c
}

; vector = vector op scalar, float, masked
define <16 x float> @test11(i32 %mask, <16 x float> %a, float %b) { ; CHECK: test11
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat

	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %mask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.mask v0, s0, v0, s1

	ret <16 x float> %c
}

; vector = vector op scalar, float, invert mask
define <16 x float> @test12(i32 %mask, <16 x float> %a, float %b) { ; CHECK: test12
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat
	%notmask = xor i32 %mask, -1

	%c = call <16 x float> @llvm.vectorproc.__builtin_vp_blendf(i32 %notmask, <16 x float> %sum, <16 x float> %a)

	; CHECK: add.f.invmask v0, s0, v0, s1

	ret <16 x float> %c
}

; vector = unaryop vector, masked
define <16 x i32> @test13(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test13
	%res = call <16 x i32> @llvm.ctlz.v16i32(<16 x i32> %b, i1 0)
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %res, <16 x i32> %a)

	; CHECK: clz.mask v0, s0, v1

	ret <16 x i32> %c
}

; vector = unaryop vector, invert mask
define <16 x i32> @test14(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test14
	%res = call <16 x i32> @llvm.ctlz.v16i32(<16 x i32> %b, i1 0)
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %res, <16 x i32> %a)

	; CHECK: clz.invmask v0, s0, v1

	ret <16 x i32> %c
}

; vector = unaryop scalar, masked
define <16 x i32> @test15(i32 %mask, <16 x i32> %a, i32 %b) {	; CHECK: test15
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer

	%res = call <16 x i32> @llvm.ctlz.v16i32(<16 x i32> %splat, i1 0)
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %res, <16 x i32> %a)

	; CHECK: clz.mask v0, s0, s1

	ret <16 x i32> %c
}

; vector = unaryop scalar, invert mask
define <16 x i32> @test16(i32 %mask, <16 x i32> %a, i32 %b) {	; CHECK: test15
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer

	%res = call <16 x i32> @llvm.ctlz.v16i32(<16 x i32> %splat, i1 0)
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %res, <16 x i32> %a)

	; CHECK: clz.invmask v0, s0, s1

	ret <16 x i32> %c
}

; Register move, vector = vector, masked
define <16 x i32> @test17(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test17
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %a, <16 x i32> %b)

	; CHECK: move.mask v{{[0-9]+}}, s0, v0

	ret <16 x i32> %c
}

; Register move, vector = vector, inverted mask
define <16 x i32> @test18(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test18
	%notmask = xor i32 %mask, -1
	%c = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %a, <16 x i32> %b)

	; CHECK: move.invmask v{{[0-9]+}}, s0, v0

	ret <16 x i32> %c
}

; XXX vector = scalar, inverted and non-inverted


; Shuffle, masked
define <16 x i32> @test19(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test19
	%shuffled = call <16 x i32> @llvm.vectorproc.__builtin_vp_shufflei(<16 x i32> %a, <16 x i32> %b)
	%blended = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %mask, <16 x i32> %shuffled, <16 x i32> %a)

	; CHECK: shuffle.mask v{{[0-9]+}}, s0, v0

	ret <16 x i32> %blended
}


; Shuffle, invert mask
define <16 x i32> @test20(i32 %mask, <16 x i32> %a, <16 x i32> %b) {	; CHECK: test20
	%notmask = xor i32 %mask, -1
	%shuffled = call <16 x i32> @llvm.vectorproc.__builtin_vp_shufflei(<16 x i32> %a, <16 x i32> %b)
	%blended = call <16 x i32> @llvm.vectorproc.__builtin_vp_blendi(i32 %notmask, <16 x i32> %shuffled, <16 x i32> %a)

	; CHECK: shuffle.invmask v{{[0-9]+}}, s0, v0

	ret <16 x i32> %blended
}


