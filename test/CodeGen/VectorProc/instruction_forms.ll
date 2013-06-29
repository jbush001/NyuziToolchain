; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; Test various arithmetic instruction formats 
; ** scalar/scalar and vector/vector are covered in operator tests. **

; vector = vector op scalar, integer
define <16 x i32> @ivvs(<16 x i32> %a, i32 %b) { ; CHECK: ivvs:
	%single = insertelement <16 x i32> undef, i32 %b, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %a, %splat
	; CHECK: v{{[0-9]+}} = v0 + s0
	ret <16 x i32> %sum
}

; vector = vector op vector, integer, masked
define <16 x i32> @ivvvm(<16 x i32> %a, <16 x i32> %b) { ; CHECK: ivvvm:
	%mask = icmp ult <16 x i32> %a, %b
	%newval = add <16 x i32> %a, %b
	%z = select <16 x i1> %mask, <16 x i32> %newval, <16 x i32> %a

	; CHECK: v{{[0-9]+}}{s{{[0-9]+}}} = v{{[0-9]+}} + v{{[0-9]+}}
	
	ret <16 x i32> %z
}

; vector = vector op immediate, integer
define <16 x i32> @ivvi(<16 x i32> %a) {	; CHECK: ivvi:
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	; CHECK: v{{[0-9]+}} = v{{[0-9]+}} + 48
	ret <16 x i32> %sum
}

; vector = vector op immediate, integer, masked
define <16 x i32> @ivvim(<16 x i32> %a, <16 x i32> %b) {	; CHECK: ivvim:
	%mask = icmp ult <16 x i32> %a, %b
	%sum = add <16 x i32> %a, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	%z = select <16 x i1> %mask, <16 x i32> %sum, <16 x i32> %a

	; CHECK: v{{[0-9]+}}{s{{[0-9]+}}} = v{{[0-9]+}} + 48

	ret <16 x i32> %z
}

; vector = scalar op immediate, integer, masked
define <16 x i32> @ivsi(i32 %a) {	; CHECK: ivsi:
	%single = insertelement <16 x i32> undef, i32 %a, i32 0 
	%splat = shufflevector <16 x i32> %single, <16 x i32> undef, 
                           <16 x i32> zeroinitializer
	%sum = add <16 x i32> %splat, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
	    i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>

	; CHECK: v{{[0-9]+}} = s0 + 48
	ret <16 x i32> %sum
}

; XXX vector = scalar op immediate, integer, masked

; vector = vector op scalar, float
define <16 x float> @fvvs(<16 x float> %a, float %b) { ; CHECK: fvvs:
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat
	; CHECK: vf{{[0-9]+}} = vf0 + f0
	ret <16 x float> %sum
}

; vector = vector op scalar, float, masked
define <16 x float> @fvvsm(<16 x float> %a, float %b, <16 x float> %c) { ; CHECK: fvvsm:
	%mask = fcmp ult <16 x float> %a, %c
	%single = insertelement <16 x float> undef, float %b, i32 0 
	%splat = shufflevector <16 x float> %single, <16 x float> undef, 
                           <16 x i32> zeroinitializer
	%sum = fadd <16 x float> %a, %splat
	%z = select <16 x i1> %mask, <16 x float> %sum, <16 x float> %a

	; CHECK: vf{{[0-9]+}}{s{{[0-9]}}} = vf0 + f0

	ret <16 x float> %z
}

