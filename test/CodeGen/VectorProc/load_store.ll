; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @loads8(i8* %p) { 		; CHECK: loads8
        %tmp = load i8* %p           
        %tmp1 = sext i8 %tmp to i32  	; CHECK: s0 = mem_b[s0]
        ret i32 %tmp1
}

define i32 @loadu8(i8* %p) { 		; CHECK: loadu8
        %tmp = load i8* %p           
        %tmp1 = zext i8 %tmp to i32  	; CHECK: u0 = mem_b[s0]
        ret i32 %tmp1
}

define i32 @loads16(i16* %p) { 		; CHECK: loads16
        %tmp = load i16* %p           
        %tmp1 = sext i16 %tmp to i32  	; CHECK: s0 = mem_s[s0]
        ret i32 %tmp1
}

define i32 @loadu16(i16* %p) { 		; CHECK: loadu16
        %tmp = load i16* %p     
        %tmp1 = zext i16 %tmp to i32  	; CHECK: u{{[0-9+]}} = mem_s[s0]
        ret i32 %tmp1
}

define i32 @loadi32(i32* %p) { 		; CHECK: loadi32
        %tmp = load i32* %p     ; CHECK: s0 = mem_l[s0]
        ret i32 %tmp
}

define float @loadf32(float* %p) { 		; CHECK: loadf32
        %tmp = load float* %p     ; CHECK: s0 = mem_l[s0]
        ret float %tmp
}

define void @store8(i8* %p, i8 %v) { 		; CHECK: store8
	store i8 %v, i8* %p, align 4		; CHECK: mem_b[s0] = s1
    ret void
}

define void @store16(i16* %p, i16 %v) { 	; CHECK: store16
	store i16 %v, i16* %p, align 4			; CHECK: mem_s[s0] = s1
    ret void
}

define void @storei32(i32* %p, i32 %v) { 		; CHECK: storei32
	store i32 %v, i32* %p, align 4		; CHECK: mem_l[s0] = s1
    ret void
}

define void @storef32(float* %p, float %v) { 		; CHECK: storef32
	store float %v, float* %p, align 4		; CHECK: mem_l[s0] = s1
    ret void
}

define void @storeivec(<16 x i32>* %ptr, <16 x i32> %val) {	; CHECK: storeivec
	store <16 x i32> %val, <16 x i32>* %ptr, align 64	; CHECK: mem_l[s0] = v0
	ret void
}

define <16 x i32> @loadivec(<16 x i32>* %ptr) { ; CHECK: loadivec
	%tmp = load <16 x i32>* %ptr	; CHECK: v0 = mem_l[s0]
	ret <16 x i32> %tmp
}

define void @storefvec(<16 x float>* %ptr, <16 x float> %val) { ; CHECK: storefvec
	store <16 x float> %val, <16 x float>* %ptr, align 64 ; CHECK: mem_l[s0] = v0
	ret void
}

define <16 x float> @loadfvec(<16 x float>* %ptr) { ; CHECK: loadfvec
	%tmp = load <16 x float>* %ptr	 ; CHECK: v0 = mem_l[s0]
	ret <16 x float> %tmp
}
