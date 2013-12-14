; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x float>* @bug() {
	%array = alloca [16 x <16 x float>], align 64
	%ep = getelementptr inbounds [16 x <16 x float>]* %array, i32 0, i32 2

	; CHECK: sub_i sp, sp, 1024

	ret <16 x float>* %ep
}
