; Vector predication 
; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @sum(<16 x i32> %param) {
	%sum = add <16 x i32> %param, <i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, 
		i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48, i32 48>
	
	ret <16 x i32> %sum
}

