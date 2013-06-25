; Vector predication 
; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @max() #0 {
entry:
	%0 = alloca <16 x i32>
	%1 = alloca <16 x i32>
	%2 = alloca <16 x i32>

	%x = load <16 x i32>* %0
	%y = load <16 x i32>* %1
	%mask = icmp ult <16 x i32> %x, %y
	%oldval = load <16 x i32>* %2

	%newval = add <16 x i32> %x, %y
	%z = select <16 x i1> %mask, <16 x i32> %newval, <16 x i32> %oldval

	store <16 x i32> %z, <16 x i32>* %0
	
	ret i32 0
}

; CHECK: v{{[0-9]+}}{s{{[0-9]+}}} = v{{[0-9]+}} + v{{[0-9]+}}
