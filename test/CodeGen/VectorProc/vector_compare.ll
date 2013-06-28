; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @cmpisgt(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpisgt
	%cmp = icmp sgt <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} > v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpiugt(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpiugt
	%cmp = icmp ugt <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = vu{{[0-9]+}} > vu{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpisge(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpisge
	%cmp = icmp sge <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} >= v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpiuge(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpiuge
	%cmp = icmp uge <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = vu{{[0-9]+}} >= vu{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpislt(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpislt
	%cmp = icmp slt <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} < v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpiult(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpiult
	%cmp = icmp ult <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = vu{{[0-9]+}} < vu{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32
	ret i32 %ret
}

define i32 @cmpisle(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpisle
	%cmp = icmp sle <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} <= v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpiule(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpiule
	%cmp = icmp ule <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = vu{{[0-9]+}} <= vu{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpieq(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpieq
	%cmp = icmp eq <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} == v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpine(<16 x i32> %a, <16 x i32> %b) #0 {	; CHECK: cmpine
	%cmp = icmp ne <16 x i32> %a, %b			; CHECK: s{{[0-9]+}} = v{{[0-9]+}} <> v{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

; <16 x float>ing point

define i32 @cmpfgt(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfgt
	%cmp = fcmp ogt <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} > vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfge(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfge
	%cmp = fcmp oge <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} >= vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpflt(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpflt
	%cmp = fcmp olt <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} < vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfle(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfle
	%cmp = fcmp ole <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} <= vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfeq(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfeq
	%cmp = fcmp oeq <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} == vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfne(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfne
	%cmp = fcmp one <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} <> vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfgtu(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfgtu
	%cmp = fcmp ugt <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} > vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfgeu(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfgeu
	%cmp = fcmp uge <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} >= vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfltu(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfltu
	%cmp = fcmp ult <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} < vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfleu(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfleu
	%cmp = fcmp ule <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} <= vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfequ(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfequ
	%cmp = fcmp ueq <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} == vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}

define i32 @cmpfneu(<16 x float> %a, <16 x float> %b) #0 {	; CHECK: cmpfneu
	%cmp = fcmp une <16 x float> %a, %b			; CHECK: s{{[0-9]+}} = vf{{[0-9]+}} <> vf{{[0-9]+}}
	%cnv = bitcast <16 x i1> %cmp to i16
	%ret = zext i16 %cnv to i32

	ret i32 %ret
}