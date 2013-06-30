; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @testi(<16 x i32> %a, i32 %b) {	; CHECK: testi:
	%elem = extractelement <16 x i32> %a, i32 %b
	
	; CHECK: s{{[0-9]+}} = getfield(v{{[0-9]+}}, s{{[0-9]+}})

	ret i32 %elem
}

define float @testf(<16 x float> %a, i32 %b) {	; CHECK: testf:
	%elem = extractelement <16 x float> %a, i32 %b
	
	; CHECK: f{{[0-9]+}} = getfield(vf{{[0-9]+}}, s{{[0-9]+}})

	ret float %elem
}
