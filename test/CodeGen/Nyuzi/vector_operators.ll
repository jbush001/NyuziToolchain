; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define <16 x i32> @add(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: add:
	%1 = add <16 x i32> %a, %b 			; CHECK: add_i v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @sub(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: sub:
	%1 = sub <16 x i32> %a, %b 			; CHECK: sub_i v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @mul(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: mul:
	%1 = mul <16 x i32> %a, %b 			; CHECK: mul_i v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @and(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: and:
	%1 = and <16 x i32> %a, %b 			; CHECK: and v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @or(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: or:
	%1 = or <16 x i32> %a, %b 			; CHECK: or v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @xor(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: xor:
	%1 = xor <16 x i32> %a, %b 			; CHECK: xor v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @shl(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: shl:
	%1 = shl <16 x i32> %a, %b 			; CHECK: shl v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x i32> @ashr(<16 x i32> %a, <16 x i32> %b) { 	; CHECK: ashr:
	%1 = ashr <16 x i32> %a, %b 			; CHECK: ashr v{{[0-9]+}}, v0, v1
	ret <16 x i32> %1
}

define <16 x float> @fadd(<16 x float> %a, <16 x float> %b) { 	; CHECK: fadd:
	%1 = fadd <16 x float> %a, %b 			; CHECK: add_f v{{[0-9]+}}, v0, v1
	ret <16 x float> %1
}

define <16 x float> @fsub(<16 x float> %a, <16 x float> %b) { 	; CHECK: fsub:
	%1 = fsub <16 x float> %a, %b 			; CHECK: sub_f v{{[0-9]+}}, v0, v1
	ret <16 x float> %1
}

define <16 x float> @fmul(<16 x float> %a, <16 x float> %b) { 	; CHECK: fmul:
	%1 = fmul <16 x float> %a, %b 			; CHECK: mul_f v{{[0-9]+}}, v0, v1
	ret <16 x float> %1
}

declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_shufflei(<16 x i32> %a, <16 x i32> %b)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_shufflef(<16 x float> %a, <16 x i32> %b)

define <16 x i32> @shufflei(<16 x i32> %a, <16 x i32> %b) {	; CHECK: shufflei:
	%shuffled = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_shufflei(<16 x i32> %a, <16 x i32> %b)

	; CHECK: shuffle v{{[0-9]+}}, v0, v1

	ret <16 x i32> %shuffled
}

define <16 x float> @shufflef(<16 x float> %a, <16 x i32> %b) {	; CHECK: shufflef:
	%shuffled = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_shufflef(<16 x float> %a, <16 x i32> %b)

	; CHECK: shuffle v{{[0-9]+}}, v0, v1

	ret <16 x float> %shuffled
}

