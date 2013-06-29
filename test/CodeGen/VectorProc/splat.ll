; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; vector = vector op scalar, int
define <16 x i32> @ivvs(<16 x i32> %a, i32 %b) { ; CHECK: ivvs:
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %a, %splat
	; CHECK: v{{[0-9]+}} = v0 + s0
	ret <16 x i32> %sum
}

; vector = vector op immediate, int
define <16 x i32> @ivvi(<16 x i32> %a) {	; CHECK: ivvi:
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	; CHECK: v{{[0-9]+}} = v{{[0-9]+}} + 48
	ret <16 x i32> %sum
}

; vector = scalar op immediate, int
define <16 x i32> @ivsi(i32 %a) {	; CHECK: ivsi:
	%single = insertelement <16 x i32> undef, i32 %a, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %splat, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	; CHECK: v{{[0-9]+}} = s0 + 48
	ret <16 x i32> %sum
}

; vector = vector op scalar, float
define <16 x float> @fvvs(<16 x float> %a, float %b) { ; CHECK: fvvs:
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat
	; CHECK: vf{{[0-9]+}} = vf0 + f0
	ret <16 x float> %sum
}

;; XXX test all other forms, with/without masks