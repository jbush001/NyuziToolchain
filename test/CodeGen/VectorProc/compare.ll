; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @cmpigt(i32 %a, i32 %b) #0 {	; CHECK: cmpigt
	%cmp = icmp sgt i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} > s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpige(i32 %a, i32 %b) #0 {	; CHECK: cmpige
	%cmp = icmp sge i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} >= s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpilt(i32 %a, i32 %b) #0 {	; CHECK: cmpilt
	%cmp = icmp slt i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} < s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpile(i32 %a, i32 %b) #0 {	; CHECK: cmpile
	%cmp = icmp sle i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} <= s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpieq(i32 %a, i32 %b) #0 {	; CHECK: cmpieq
	%cmp = icmp eq i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} == s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpine(i32 %a, i32 %b) #0 {	; CHECK: cmpine
	%cmp = icmp ne i32 %a, %b			; CHECK: s{{[0-9]+}} = s{{[0-9]+}} <> s{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

; Floating point

define i32 @cmpfgt(float %a, float %b) #0 {	; CHECK: cmpfgt
	%cmp = fcmp ogt float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} > f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfge(float %a, float %b) #0 {	; CHECK: cmpfge
	%cmp = fcmp oge float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} >= f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpflt(float %a, float %b) #0 {	; CHECK: cmpflt
	%cmp = fcmp olt float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} < f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfle(float %a, float %b) #0 {	; CHECK: cmpfle
	%cmp = fcmp ole float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} <= f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfeq(float %a, float %b) #0 {	; CHECK: cmpfeq
	%cmp = fcmp oeq float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} == f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}

define i32 @cmpfne(float %a, float %b) #0 {	; CHECK: cmpfne
	%cmp = fcmp one float %a, %b			; CHECK: f{{[0-9]+}} = f{{[0-9]+}} <> f{{[0-9]+}}
	%ret = zext i1 %cmp to i32
	ret i32 %ret
}
