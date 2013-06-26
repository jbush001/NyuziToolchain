; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @test() #0 {
entry:
	%0 = alloca <16 x i32>
	%1 = load <16 x i32>* %0
	%2 = alloca i32, align 4
	%3 = load i32* %2
	%4 = extractelement <16 x i32> %1, i32 %3
	ret i32 %4
}

; CHECK: s{{[0-9]+}} = getfield(v{{[0-9]+}}, s{{[0-9]+}})
