; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

declare i32 @llvm.nyuzi.__builtin_nyuzi_read_control_reg(i32 %reg)
declare void @llvm.nyuzi.__builtin_nyuzi_write_control_reg(i32 %reg, i32 %value)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi(<16 x i32> %a)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf(<16 x i32> %a)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi_masked(<16 x i32> %a, i32 %mask)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf_masked(<16 x i32> %a, i32 %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storei(<16 x i32> %ptr, 
	<16 x i32> %value)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storef(<16 x i32> %ptr, 
	<16 x float> %value)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storei_masked(<16 x i32> %ptr, 
	<16 x i32> %value, i32 %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storef_masked(<16 x i32> %ptr, 
	<16 x float> %value, i32 %mask)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_block_loadi_masked(<16 x i32>* %ptr, 
	i32 %mask)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_block_loadf_masked(<16 x i32>* %ptr, 
	i32 %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_block_storei_masked(<16 x i32>* %ptr, 
	<16 x i32> %value, i32 %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_block_storef_masked(<16 x i32>* %ptr, 
	<16 x float> %value, i32 %mask)
declare i32 @llvm.ctlz.i32(i32 %val)
declare i32 @llvm.cttz.i32(i32 %val)

define i32 @get_control_reg() {	; CHECK: get_control_reg:
	%1 = call i32 @llvm.nyuzi.__builtin_nyuzi_read_control_reg(i32 7)
	; CHECK: getcr s0, 7

	ret i32 %1
}

define void @set_control_reg(i32 %value) {	; CHECK: set_control_reg:
	call void @llvm.nyuzi.__builtin_nyuzi_write_control_reg(i32 7, i32 %value)
	; CHECK: setcr s0, 7

	ret void
}

define <16 x i32> @gather_loadi(<16 x i32> %ptr) {	; CHECK: gather_loadi:
entry:
	%0 = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi(<16 x i32> %ptr)
	; CHECK: load_gath v0, (v0)

	ret <16 x i32> %0
}

define <16 x float> @gather_loadf(<16 x i32> %ptr) {	; CHECK: gather_loadf:
	%1 = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf(<16 x i32> %ptr)
	; CHECK: load_gath v0, (v0)

	ret <16 x float> %1
}

define <16 x i32> @gather_loadi_masked(<16 x i32> %ptr, i32 %mask) { ; CHECK: gather_loadi_masked:
entry:
	%0 = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi_masked(<16 x i32> %ptr, i32 %mask)
	; CHECK: load_gath_mask v0, s0, (v0)

	ret <16 x i32> %0
}

define <16 x float> @gather_loadf_masked(<16 x i32> %ptr, i32 %mask) {	; CHECK: gather_loadf_masked:
	%1 = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf_masked(<16 x i32> %ptr, i32 %mask)
	; CHECK: load_gath_mask v0, s0, (v0)

	ret <16 x float> %1
}

define void @scatter_storei(<16 x i32> %ptr, <16 x i32> %value) { ; CHECK: scatter_storei:
	call void @llvm.nyuzi.__builtin_nyuzi_scatter_storei(<16 x i32> %ptr, <16 x i32> %value)
	; CHECK: store_scat v1, (v0)

	ret void
}

define void @scatter_storef(<16 x i32> %ptr, <16 x float> %value) { ; CHECK: scatter_storef:
	call void @llvm.nyuzi.__builtin_nyuzi_scatter_storef(<16 x i32> %ptr, <16 x float> %value)

	; CHECK: store_scat v1, (v0)

	ret void
}

define void @scatter_storei_masked(<16 x i32> %ptr, <16 x i32> %value, i32 %mask) { ; CHECK: scatter_storei_masked:
	call void @llvm.nyuzi.__builtin_nyuzi_scatter_storei_masked(<16 x i32> %ptr, <16 x i32> %value, i32 %mask)

	; CHECK: store_scat_mask v1, s0, (v0)

	ret void
}

define void @scatter_storef_masked(<16 x i32> %ptr, <16 x float> %value, i32 %mask) { ; CHECK: scatter_storef_masked:
	call void @llvm.nyuzi.__builtin_nyuzi_scatter_storef_masked(<16 x i32> %ptr, <16 x float> %value, i32 %mask)

	; CHECK: store_scat_mask v1, s0, (v0)

	ret void
}

define <16 x i32> @test_block_loadi_masked(<16 x i32>* %ptr, i32 %mask) {
	%result = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_block_loadi_masked(
		<16 x i32>* %ptr, i32 %mask)

	; CHECK: load_v_mask v0, s1, (s0)

	ret <16 x i32> %result
}

define <16 x float> @test_block_loadf_masked(<16 x i32>* %ptr, i32 %mask) {
	%result = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_block_loadf_masked(
		<16 x i32>* %ptr, i32 %mask)

	; CHECK: load_v_mask v0, s1, (s0)

	ret <16 x float> %result
}

define void @test_block_storei_masked(<16 x i32>* %ptr, <16 x i32> %value, i32 %mask) {
	call void @llvm.nyuzi.__builtin_nyuzi_block_storei_masked(<16 x i32>* %ptr, 
		<16 x i32> %value, i32 %mask)

	; CHECK: store_v_mask v0, s1, (s0)

	ret void
}

define void @test_block_storef_masked(<16 x i32>* %ptr, <16 x float> %value, i32 %mask) {
  call void @llvm.nyuzi.__builtin_nyuzi_block_storef_masked(<16 x i32>* %ptr, 
  	<16 x float> %value, i32 %mask)

  ; CHECK: store_v_mask v0, s1, (s0)

  ret void
}

; Count leading zeros
define i32 @test_builtin_ctlz(i32 %val) {	; CHECK: test_builtin_ctlz:
	%ret = call i32 @llvm.ctlz.i32(i32 %val)
	; CHECK: clz s0, s0
	
	ret i32 %ret
}

; Count trailing zeros
define i32 @test_builtin_cttz(i32 %val) {	; CHECK: test_builtin_cttz:
	%ret = call i32 @llvm.cttz.i32(i32 %val)
	; CHECK: ctz s0, s0
	
	ret i32 %ret
}

