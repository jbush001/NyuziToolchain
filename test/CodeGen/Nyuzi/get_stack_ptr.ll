; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define <16 x float>* @bug() {
	%array = alloca [16 x <16 x float>], align 64
	%ep = getelementptr inbounds [16 x <16 x float>], [16 x <16 x float>]* %array, i32 0, i32 0

	; CHECK: add_i sp, sp, -1024
  ; CHECK: .cfi_def_cfa_offset 1024
  ; CHECK: lea s0, (sp)

	ret <16 x float>* %ep
}
