; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @cmpisgt(i32 %a, i32 %b) #0 {	; CHECK: cmpisgt:
	%cmp = icmp sgt i32 %a, %b			; CHECK: setgt_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiugt(i32 %a, i32 %b) #0 {	; CHECK: cmpiugt:
	%cmp = icmp ugt i32 %a, %b			; CHECK: setgt_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpisge(i32 %a, i32 %b) #0 {	; CHECK: cmpisge:
	%cmp = icmp sge i32 %a, %b			; CHECK: setge_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiuge(i32 %a, i32 %b) #0 {	; CHECK: cmpiuge:
	%cmp = icmp uge i32 %a, %b			; CHECK: setge_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpislt(i32 %a, i32 %b) #0 {	; CHECK: cmpislt:
	%cmp = icmp slt i32 %a, %b			; CHECK: setlt_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiult(i32 %a, i32 %b) #0 {	; CHECK: cmpiult:
	%cmp = icmp ult i32 %a, %b			; CHECK: setlt_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpisle(i32 %a, i32 %b) #0 {	; CHECK: cmpisle:
	%cmp = icmp sle i32 %a, %b			; CHECK: setle_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpiule(i32 %a, i32 %b) #0 {	; CHECK: cmpiule:
	%cmp = icmp ule i32 %a, %b			; CHECK: setle_u s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpieq(i32 %a, i32 %b) #0 {	; CHECK: cmpieq:
	%cmp = icmp eq i32 %a, %b			; CHECK: seteq_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpine(i32 %a, i32 %b) #0 {	; CHECK: cmpine:
	%cmp = icmp ne i32 %a, %b			; CHECK: setne_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

; Floating point

define i32 @cmpfgt(float %a, float %b) #0 {	; CHECK: cmpfgt:
	%cmp = fcmp ogt float %a, %b			; CHECK: setgt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfge(float %a, float %b) #0 {	; CHECK: cmpfge:
	%cmp = fcmp oge float %a, %b			; CHECK: setge_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpflt(float %a, float %b) #0 {	; CHECK: cmpflt:
	%cmp = fcmp olt float %a, %b			; CHECK: setlt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfle(float %a, float %b) #0 {	; CHECK: cmpfle:
	%cmp = fcmp ole float %a, %b			; CHECK: setle_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfeq(float %a, float %b) #0 {	; CHECK: cmpfeq:
	%cmp = fcmp oeq float %a, %b			; CHECK: seteq_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfne(float %a, float %b) #0 {	; CHECK: cmpfne:
	%cmp = fcmp one float %a, %b			; CHECK: setne_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfgtu(float %a, float %b) #0 {	; CHECK: cmpfgtu:
	%cmp = fcmp ugt float %a, %b			; CHECK: setgt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfgeu(float %a, float %b) #0 {	; CHECK: cmpfgeu:
	%cmp = fcmp uge float %a, %b			; CHECK: setge_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfltu(float %a, float %b) #0 {	; CHECK: cmpfltu:
	%cmp = fcmp ult float %a, %b			; CHECK: setlt_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfleu(float %a, float %b) #0 {	; CHECK: cmpfleu:
	%cmp = fcmp ule float %a, %b			; CHECK: setle_f s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfequ(float %a, float %b) #0 {	; CHECK: cmpfequ:
	%cmp = fcmp ueq float %a, %b			; CHECK: seteq_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfneu(float %a, float %b) #0 {	; CHECK: cmpfneu:
	%cmp = fcmp une float %a, %b			; CHECK: setne_i s{{[0-9]+}}, s0, s1
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}