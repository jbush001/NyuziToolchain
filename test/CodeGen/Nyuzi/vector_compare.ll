; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sgt(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sge(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_slt(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sle(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_eq(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ne(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ugt(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_uge(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ult(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ule(<16 x i32> %a, <16 x i32> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_gt(<16 x float> %a, <16 x float> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_ge(<16 x float> %a, <16 x float> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_lt(<16 x float> %a, <16 x float> %b)
declare i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_le(<16 x float> %a, <16 x float> %b)

define i32 @cmpisgt(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpisgt
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sgt(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpgt_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpisge(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpisge
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sge(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpge_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpislt(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpislt
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_slt(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmplt_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpisle(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpisle
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_sle(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmple_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpieq(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpieq
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_eq(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpeq_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpine(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpine
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ne(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpne_i s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpiugt(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpiugt
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ugt(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpgt_u s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpiuge(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpiuge
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_uge(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmpge_u s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpiult(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpiult
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ult(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmplt_u s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpiule(<16 x i32> %a, <16 x i32> %b) {	; CHECK: cmpiule
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpi_ule(<16 x i32> %a, <16 x i32> %b)

	; CHECK: cmple_u s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpfgt(<16 x float> %a, <16 x float> %b) {	; CHECK: cmpfgt
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_gt(<16 x float> %a, <16 x float> %b)

	; CHECK: cmpgt_f s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpfge(<16 x float> %a, <16 x float> %b) {	; CHECK: cmpfge
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_ge(<16 x float> %a, <16 x float> %b)

	; CHECK: cmpge_f s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpflt(<16 x float> %a, <16 x float> %b) {	; CHECK: cmpflt
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_lt(<16 x float> %a, <16 x float> %b)

	; CHECK: cmplt_f s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

define i32 @cmpfle(<16 x float> %a, <16 x float> %b) {	; CHECK: cmpfle
	%c = call i32 @llvm.nyuzi.__builtin_nyuzi_mask_cmpf_le(<16 x float> %a, <16 x float> %b)

	; CHECK: cmple_f s{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}

	ret i32 %c
}

