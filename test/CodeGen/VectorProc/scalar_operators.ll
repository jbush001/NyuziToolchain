; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @add(i32 %a, i32 %b) { 	; CHECK: add:
	%1 = add i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} + s{{[0-9]+}}
	ret i32 %1
}

define i32 @sub(i32 %a, i32 %b) { 	; CHECK: sub:
	%1 = sub i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} - s{{[0-9]+}}
	ret i32 %1
}

define i32 @mul(i32 %a, i32 %b) { 	; CHECK: mul:
	%1 = mul i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} * s{{[0-9]+}}
	ret i32 %1
}

define i32 @and(i32 %a, i32 %b) { 	; CHECK: and:
	%1 = and i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} & s{{[0-9]+}}
	ret i32 %1
}

define i32 @or(i32 %a, i32 %b) { 	; CHECK: or:
	%1 = or i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} | s{{[0-9]+}}
	ret i32 %1
}

define i32 @xor(i32 %a, i32 %b) { 	; CHECK: xor:
	%1 = xor i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} ^ s{{[0-9]+}}
	ret i32 %1
}

define i32 @shl(i32 %a, i32 %b) { 	; CHECK: shl:
	%1 = shl i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} << s{{[0-9]+}}
	ret i32 %1
}


define i32 @ashr(i32 %a, i32 %b) { 	; CHECK: ashr:
	%1 = ashr i32 %a, %b 			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} >> s{{[0-9]+}}
	ret i32 %1
}

; XXXXX Currently broken, can't return float
;define float @fadd(float %a, float %b) { 	; CHECK: fadd:
;	%1 = fadd float %a, %b 			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} + f{{[0-9]+}}
;	ret float %1
;}

; XXXXX Currently broken, can't return float
;define float @fsub(float %a, float %b) { 	; CHECK: fsub:
;	%1 = fsub float %a, %b 			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} - f{{[0-9]+}}
;	ret float %1
;}

; XXXXX Currently broken, can't return float
;define float @fmul(float %a, float %b) { 	; CHECK: fmul:
;	%1 = fmul float %a, %b 			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} * f{{[0-9]+}}
;	ret float %1
;}

; XXXXX Currently broken, doesn't convert to unsigned operands
;define i32 @lshr(i32 %a, i32 %b) { 	; CHECK: lshr:
;	%1 = lshr i32 %a, %b 			; CHECK: u{{[0-9]+}} = u{{[0-9]+}} >> u{{[0-9]+}}
;	ret i32 %1
;}

; Missing: udiv, sdiv, urem, srem, frem


