; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @seli(i32 %a) {  ;CHECK: seli:
entry:
    %cmp = icmp eq i32 %a, 4
	; CHECK: [[PRED:s[0-9]+]] = s0 == 4

    %val = select i1 %cmp, i32 2, i32 3
	; CHECK: if [[PRED]] goto [[TRUELABEL:[A-Z0-9a-z_]+]]
	; s{{[0-9]+}} = [0-9]+
	; [[TRUELABEL]]:
    
    ret i32 %val
}

define float @self(float %a, float %b, float %c) {  ;CHECK: self:
entry:
    %cmp = fcmp oeq float %a, %b
	; CHECK: [[PRED:s[0-9]+]] = f0 == f1

    %val = select i1 %cmp, float %b, float %c

	; CHECK: if [[PRED]] goto [[TRUELABEL:[A-Z0-9a-z_]+]]
	; [[TRUELABEL]]:
    
    ret float %val
}

define <16 x i32> @selvi(i32 %a, <16 x i32> %b, <16 x i32> %c) {  ; CHECK: selvi:
entry:
    %cmp = icmp eq i32 %a, 4
	; CHECK: [[PRED:s[0-9]+]] = s0 == 4

    %val = select i1 %cmp, <16 x i32> %b, <16 x i32> %c
	; CHECK: if [[PRED]] goto [[TRUELABEL:[A-Z0-9a-z_]+]]
	; v{{[0-9]+}} = v0
	; [[TRUELABEL]]:
    
    ret <16 x i32> %val
}

define <16 x float> @selvf(i32 %a, <16 x float> %b, <16 x float> %c) {  ; CHECK: selvf:
entry:
    %cmp = icmp eq i32 %a, 4
	; CHECK: [[PRED:s[0-9]+]] = s0 == 4

    %val = select i1 %cmp, <16 x float> %b, <16 x float> %c
	; CHECK: if [[PRED]] goto [[TRUELABEL:[A-Z0-9a-z_]+]]
	; v{{[0-9]+}} = v0
	; [[TRUELABEL]]:
    
    ret <16 x float> %val
}

