; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @test(<16 x i32> %a, i32 %b) #0 {
	%elem = extractelement <16 x i32> %a, i32 %b
	ret i32 %elem
}

; CHECK: s{{[0-9]+}} = getfield(v{{[0-9]+}}, s{{[0-9]+}})
