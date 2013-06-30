; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @loadconst(i32 %a, i32 %b, <16 x i32> %c) {
	%cmp = icmp sgt i32 %a, %b
	%res = select i1 %cmp, <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>, <16 x i32> <i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0, i32 -48, i32 -32, i32 -16, i32 0>
	; CHECK: s{{[0-9]+}} = &L{{[A-Z0-9_a-z]+}}
	ret <16 x i32> %res
}



