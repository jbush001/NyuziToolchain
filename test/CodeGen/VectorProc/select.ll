; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @sel(i32 %a) {  ;CHECK: sel:
entry:
    %cmp = icmp eq i32 %a, 4
	; CHECK: [[PRED:s[0-9]+]] = s0 == 4

    %val = select i1 %cmp, i32 2, i32 3
	; CHECK: if [[PRED]] goto [[TRUELABEL:[A-Z0-9a-z_]+]]
	; s{{[0-9]+}} = [0-9]+
	; [[TRUELABEL]]:
    
    ret i32 %val
}



