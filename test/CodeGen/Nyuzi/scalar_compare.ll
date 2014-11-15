; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define i32 @cmpisgt(i32 %a, i32 %b) #0 {	; CHECK: cmpisgt:
	%cmp = icmp sgt i32 %a, %b			; CHECK: cmpgt_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiugt(i32 %a, i32 %b) #0 {	; CHECK: cmpiugt:
	%cmp = icmp ugt i32 %a, %b			; CHECK: cmpgt_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpisge(i32 %a, i32 %b) #0 {	; CHECK: cmpisge:
	%cmp = icmp sge i32 %a, %b			; CHECK: cmpge_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiuge(i32 %a, i32 %b) #0 {	; CHECK: cmpiuge:
	%cmp = icmp uge i32 %a, %b			; CHECK: cmpge_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpislt(i32 %a, i32 %b) #0 {	; CHECK: cmpislt:
	%cmp = icmp slt i32 %a, %b			; CHECK: cmplt_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiult(i32 %a, i32 %b) #0 {	; CHECK: cmpiult:
	%cmp = icmp ult i32 %a, %b			; CHECK: cmplt_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpisle(i32 %a, i32 %b) #0 {	; CHECK: cmpisle:
	%cmp = icmp sle i32 %a, %b			; CHECK: cmple_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiule(i32 %a, i32 %b) #0 {	; CHECK: cmpiule:
	%cmp = icmp ule i32 %a, %b			; CHECK: cmple_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpieq(i32 %a, i32 %b) #0 {	; CHECK: cmpieq:
	%cmp = icmp eq i32 %a, %b			; CHECK: cmpeq_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpine(i32 %a, i32 %b) #0 {	; CHECK: cmpine:
	%cmp = icmp ne i32 %a, %b			; CHECK: cmpne_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

; Floating point

define i32 @cmpfgt(float %a, float %b) #0 {	; CHECK: cmpfgt:
	%cmp = fcmp ogt float %a, %b			; CHECK: cmpgt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfge(float %a, float %b) #0 {	; CHECK: cmpfge:
	%cmp = fcmp oge float %a, %b			; CHECK: cmpge_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpflt(float %a, float %b) #0 {	; CHECK: cmpflt:
	%cmp = fcmp olt float %a, %b			; CHECK: cmplt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfle(float %a, float %b) #0 {	; CHECK: cmpfle:
	%cmp = fcmp ole float %a, %b			; CHECK: cmple_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfeq(float %a, float %b) #0 {	; CHECK: cmpfeq:
	%cmp = fcmp oeq float %a, %b			; CHECK: cmpeq_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfne(float %a, float %b) #0 {	; CHECK: cmpfne:
	%cmp = fcmp one float %a, %b			; CHECK: cmpne_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfgtu(float %a, float %b) #0 {	; CHECK: cmpfgtu:
	%cmp = fcmp ugt float %a, %b			; CHECK: cmpgt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfgeu(float %a, float %b) #0 {	; CHECK: cmpfgeu:
	%cmp = fcmp uge float %a, %b			; CHECK: cmpge_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfltu(float %a, float %b) #0 {	; CHECK: cmpfltu:
	%cmp = fcmp ult float %a, %b			; CHECK: cmplt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfleu(float %a, float %b) #0 {	; CHECK: cmpfleu:
	%cmp = fcmp ule float %a, %b			; CHECK: cmple_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfequ(float %a, float %b) #0 {	; CHECK: cmpfequ:
	%cmp = fcmp ueq float %a, %b			; CHECK: cmpeq_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfneu(float %a, float %b) #0 {	; CHECK: cmpfneu:
	%cmp = fcmp une float %a, %b			; CHECK: cmpne_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @check_notnan(float %a) #0 {  ; CHECK: check_notnan:
entry:
  %lnot = fcmp ord float %a, 0.000000e+00
  %lnot.ext = zext i1 %lnot to i32			; CHECK: cmpeq_f
  ret i32 %lnot.ext
}

; XXX broken
;define i32 @check_nan(float %a) #0 {	; NCHECK: check_nan:
;entry:
;  %lnot = fcmp uno float %a, 0.000000e+00
;  %lnot.ext = zext i1 %lnot to i32			; NCHECK: cmpeq_f
;  ret i32 %lnot.ext
;}
