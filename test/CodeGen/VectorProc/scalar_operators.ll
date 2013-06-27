; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @add(i32 %a, i32 %b) { 	; CHECK: add:
	%1 = add i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 + s1
	ret i32 %1
}

define i32 @addimm(i32 %a) { 	; CHECK: addimm:
	%1 = add i32 %a, 12 			; CHECK: s{{[0-9]+}} = s0 + 12
	ret i32 %1
}

define i32 @sub(i32 %a, i32 %b) { 	; CHECK: sub:
	%1 = sub i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 - s1
	ret i32 %1
}

define i32 @subimm(i32 %a) { 	; CHECK: subimm:
	%1 = sub i32 %a, 17 			; CHECK: s{{[0-9]+}} = s0 + -17
	ret i32 %1
}

define i32 @mul(i32 %a, i32 %b) { 	; CHECK: mul:
	%1 = mul i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 * s1
	ret i32 %1
}

define i32 @mulimm(i32 %a) { 	; CHECK: mulimm:
	%1 = mul i32 %a, 22 			; CHECK: s{{[0-9]+}} = s0 * 22
	ret i32 %1
}

define i32 @and(i32 %a, i32 %b) { 	; CHECK: and:
	%1 = and i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 & s1
	ret i32 %1
}

define i32 @andimm(i32 %a) { 	; CHECK: andimm:
	%1 = and i32 %a, 27 			; CHECK: s{{[0-9]+}} = s0 & 27
	ret i32 %1
}

define i32 @or(i32 %a, i32 %b) { 	; CHECK: or:
	%1 = or i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 | s1
	ret i32 %1
}

define i32 @orimm(i32 %a) { 	; CHECK: orimm:
	%1 = or i32 %a, 29 			; CHECK: s{{[0-9]+}} = s0 | 29
	ret i32 %1
}

define i32 @xor(i32 %a, i32 %b) { 	; CHECK: xor:
	%1 = xor i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 ^ s1
	ret i32 %1
}

define i32 @xorimm(i32 %a) { 	; CHECK: xorimm:
	%1 = xor i32 %a, 31			; CHECK: s{{[0-9]+}} = s0 ^ 31
	ret i32 %1
}

define i32 @shl(i32 %a, i32 %b) { 	; CHECK: shl:
	%1 = shl i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 << s1
	ret i32 %1
}

define i32 @shlimm(i32 %a) { 	; CHECK: shlimm:
	%1 = shl i32 %a, 7 			; CHECK: s{{[0-9]+}} = s0 << 7
	ret i32 %1
}

define i32 @ashr(i32 %a, i32 %b) { 	; CHECK: ashr:
	%1 = ashr i32 %a, %b 			; CHECK: s{{[0-9]+}} = s0 >> s1
	ret i32 %1
}

define i32 @ashrimm(i32 %a) { 	; CHECK: ashrimm:
	%1 = ashr i32 %a, 9 			; CHECK: s{{[0-9]+}} = s0 >> 9
	ret i32 %1
}

define float @fadd(float %a, float %b) { 	; CHECK: fadd:
	%1 = fadd float %a, %b 			; CHECK: f{{[0-9]+}} = f0 + f1
	ret float %1
}

define float @fsub(float %a, float %b) { 	; CHECK: fsub:
	%1 = fsub float %a, %b 			; CHECK: f{{[0-9]+}} = f0 - f1
	ret float %1
}

define float @fmul(float %a, float %b) { 	; CHECK: fmul:
	%1 = fmul float %a, %b 			; CHECK: f{{[0-9]+}} = f0 * f1
	ret float %1
}

; Broken: lshr (doesn't use unsigned operands)
; Not implemented: udiv, sdiv, urem, srem, frem


