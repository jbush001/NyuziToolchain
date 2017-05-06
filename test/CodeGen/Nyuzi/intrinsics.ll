; RUN: llc %s -o - | FileCheck %s
;
; Test Nyuzi specific intrinsics
;

target triple = "nyuzi-elf-none"

declare i32 @llvm.nyuzi.__builtin_nyuzi_read_control_reg(i32 %reg)
declare void @llvm.nyuzi.__builtin_nyuzi_write_control_reg(i32 %reg, i32 %value)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi(<16 x i32> %a)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf(<16 x i32> %a)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi_masked(<16 x i32> %a, <16 x i1> %mask)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf_masked(<16 x i32> %a, <16 x i1> %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storei(<16 x i32> %ptr,
  <16 x i32> %value)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storef(<16 x i32> %ptr,
  <16 x float> %value)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storei_masked(<16 x i32> %ptr,
  <16 x i32> %value, <16 x i1> %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_scatter_storef_masked(<16 x i32> %ptr,
  <16 x float> %value, <16 x i1> %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_block_storei_masked(<16 x i32>* %ptr,
  <16 x i32> %value, <16 x i1> %mask)
declare void @llvm.nyuzi.__builtin_nyuzi_block_storef_masked(<16 x i32>* %ptr,
  <16 x float> %value, <16 x i1> %mask)
declare i32 @llvm.ctlz.i32(i32 %val)
declare i32 @llvm.cttz.i32(i32 %val)
declare <16 x i32> @llvm.nyuzi.__builtin_nyuzi_shufflei(<16 x i32> %a, <16 x i32> %b)
declare <16 x float> @llvm.nyuzi.__builtin_nyuzi_shufflef(<16 x float> %a, <16 x i32> %b)
declare void @llvm.trap()

define i32 @get_control_reg() { ; CHECK-LABEL: get_control_reg:
  %1 = call i32 @llvm.nyuzi.__builtin_nyuzi_read_control_reg(i32 7)

  ; CHECK: getcr s0, 7

  ret i32 %1
}

define void @set_control_reg(i32 %value) { ; CHECK-LABEL: set_control_reg:
  call void @llvm.nyuzi.__builtin_nyuzi_write_control_reg(i32 7, i32 %value)

  ; CHECK: setcr s0, 7

  ret void
}

define <16 x i32> @gather_loadi(<16 x i32> %ptr) { ; CHECK-LABEL: gather_loadi:
  %1 = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi(<16 x i32> %ptr)

  ; CHECK: load_gath v0, (v0)

  ret <16 x i32> %1
}

define <16 x float> @gather_loadf(<16 x i32> %ptr) { ; CHECK-LABEL: gather_loadf:
  %1 = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf(<16 x i32> %ptr)

  ; CHECK: load_gath v0, (v0)

  ret <16 x float> %1
}

define <16 x i32> @gather_loadi_masked(<16 x i32> %ptr, <16 x i1> %mask) { ; CHECK-LABEL: gather_loadi_masked:
  %1 = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_gather_loadi_masked(<16 x i32> %ptr, <16 x i1> %mask)

  ; CHECK: load_gath_mask v0, s0, (v0)

  ret <16 x i32> %1
}

define <16 x float> @gather_loadf_masked(<16 x i32> %ptr, <16 x i1> %mask) { ; CHECK-LABEL: gather_loadf_masked:
  %1 = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_gather_loadf_masked(<16 x i32> %ptr, <16 x i1> %mask)

  ; CHECK: load_gath_mask v0, s0, (v0)

  ret <16 x float> %1
}

define void @scatter_storei(<16 x i32> %ptr, <16 x i32> %value) { ; CHECK-LABEL: scatter_storei:
  call void @llvm.nyuzi.__builtin_nyuzi_scatter_storei(<16 x i32> %ptr, <16 x i32> %value)

  ; CHECK: store_scat v1, (v0)

  ret void
}

define void @scatter_storef(<16 x i32> %ptr, <16 x float> %value) { ; CHECK-LABEL: scatter_storef:
  call void @llvm.nyuzi.__builtin_nyuzi_scatter_storef(<16 x i32> %ptr, <16 x float> %value)

  ; CHECK: store_scat v1, (v0)

  ret void
}

define void @scatter_storei_masked(<16 x i32> %ptr, <16 x i32> %value, <16 x i1> %mask) { ; CHECK-LABEL: scatter_storei_masked:
  call void @llvm.nyuzi.__builtin_nyuzi_scatter_storei_masked(<16 x i32> %ptr, <16 x i32> %value, <16 x i1> %mask)

  ; CHECK: store_scat_mask v1, s0, (v0)

  ret void
}

define void @scatter_storef_masked(<16 x i32> %ptr, <16 x float> %value, <16 x i1> %mask) { ; CHECK-LABEL: scatter_storef_masked:
  call void @llvm.nyuzi.__builtin_nyuzi_scatter_storef_masked(<16 x i32> %ptr, <16 x float> %value, <16 x i1> %mask)

  ; CHECK: store_scat_mask v1, s0, (v0)

  ret void
}

define void @test_block_storei_masked(<16 x i32>* %ptr, <16 x i32> %value, <16 x i1> %mask) { ; CHECK-LABEL: test_block_storei_masked
  call void @llvm.nyuzi.__builtin_nyuzi_block_storei_masked(<16 x i32>* %ptr,
    <16 x i32> %value, <16 x i1> %mask)

  ; CHECK: store_v_mask v0, s1, (s0)

  ret void
}

define void @test_block_storef_masked(<16 x i32>* %ptr, <16 x float> %value, <16 x i1> %mask) { ; CHECK-LABEL: test_block_storef_masked
  call void @llvm.nyuzi.__builtin_nyuzi_block_storef_masked(<16 x i32>* %ptr,
    <16 x float> %value, <16 x i1> %mask)

  ; CHECK: store_v_mask v0, s1, (s0)

  ret void
}

; Count leading zeros
define i32 @test_builtin_ctlz(i32 %val) { ; CHECK-LABEL: test_builtin_ctlz:
  %ret = call i32 @llvm.ctlz.i32(i32 %val)

  ; CHECK: clz s0, s0

  ret i32 %ret
}

; Count trailing zeros
define i32 @test_builtin_cttz(i32 %val) { ; CHECK-LABEL: test_builtin_cttz:
  %ret = call i32 @llvm.cttz.i32(i32 %val)

  ; CHECK: ctz s0, s0

  ret i32 %ret
}

define <16 x i32> @shufflei(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: shufflei:
  %shuffled = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_shufflei(<16 x i32> %a, <16 x i32> %b)

  ; CHECK: shuffle v{{[0-9]+}}, v0, v1

  ret <16 x i32> %shuffled
}

define <16 x float> @shufflef(<16 x float> %a, <16 x i32> %b) { ; CHECK-LABEL: shufflef:
  %shuffled = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_shufflef(<16 x float> %a, <16 x i32> %b)

  ; CHECK: shuffle v{{[0-9]+}}, v0, v1

  ret <16 x float> %shuffled
}

define <16 x i32> @shufflei_mask(<16 x i1> %mask, <16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: shufflei_mask:
  %shuffled = call <16 x i32> @llvm.nyuzi.__builtin_nyuzi_shufflei(<16 x i32> %a, <16 x i32> %b)
  %blended = select <16 x i1> %mask, <16 x i32> %shuffled, <16 x i32> %b

  ; CHECK: shuffle_mask v{{[0-9]+}}, s0, v0

  ret <16 x i32> %blended
}

define <16 x float> @shufflef_mask(<16 x i1> %mask, <16 x float> %a, <16 x i32> %b) { ; CHECK-LABEL: shufflef_mask:
  %shuffled = call <16 x float> @llvm.nyuzi.__builtin_nyuzi_shufflef(<16 x float> %a, <16 x i32> %b)
  %blended = select <16 x i1> %mask, <16 x float> %shuffled, <16 x float> %a

  ; CHECK: shuffle_mask v{{[0-9]+}}, s0, v0

  ret <16 x float> %blended
}

; Various mix/moves

define <16 x i32> @movevvm_i(<16 x i1> %mask, <16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: movevvm_i:
  %blended = select <16 x i1> %mask, <16 x i32> %a, <16 x i32> %b

  ; CHECK: move_mask v{{[0-9]+}}, s0, v0

  ret <16 x i32> %blended
}

define <16 x i32> @movevIm_i(<16 x i1> %mask, <16 x i32> %a) { ; CHECK-LABEL: movevIm_i:
  %blended = select <16 x i1> %mask, <16 x i32> %a,
    <16 x i32> <i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27>

  ; CHECK: move [[DEST:v[0-9]+]], 27
  ; CHECK: move_mask [[DEST]], s0, v0

  ret <16 x i32> %blended
}

define <16 x i32> @movevs_i(i32 %a) { ; CHECK-LABEL: movevs_i:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer

  ; CHECK: move [[DEST:v[0-9]+]], s0

  ret <16 x i32> %splat
}

define <16 x i32> @movevsm_i(<16 x i1> %mask, <16 x i32> %a, i32 %b) { ; CHECK-LABEL: movevsm_i:
  %single = insertelement <16 x i32> undef, i32 %b, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer

  %blended = select <16 x i1> %mask, <16 x i32> %a, <16 x i32> %splat

  ; CHECK: move [[DEST:v[0-9]+]], s1
  ; CHECK: move_mask [[DEST]], s0, v0

  ret <16 x i32> %blended
}

define <16 x float> @movevvm_f(<16 x i1> %mask, <16 x float> %a, <16 x float> %b) { ; CHECK-LABEL: movevvm_f:
  %blended = select <16 x i1> %mask, <16 x float> %a, <16 x float> %b

  ; CHECK: move_mask v{{[0-9]+}}, s0, v0

  ret <16 x float> %blended
}

define <16 x float> @movevs_f(float %a) { ; CHECK-LABEL: movevs_f:
  %single = insertelement <16 x float> undef, float %a, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer

  ; CHECK: move [[DEST:v[0-9]+]], s0

  ret <16 x float> %splat
}

define <16 x float> @movevsm_f(<16 x i1> %mask, <16 x float> %a, float %b) { ; CHECK-LABEL: movevsm_f:
  %single = insertelement <16 x float> undef, float %b, i32 0
  %splat = shufflevector <16 x float> %single, <16 x float> undef, <16 x i32> zeroinitializer

  %blended = select <16 x i1> %mask, <16 x float> %a, <16 x float> %splat

  ; CHECK: move [[DEST:v[0-9]+]], s1
  ; CHECK: move_mask [[DEST]], s0, v0

  ret <16 x float> %blended
}

define void @test_builtin_trap() {  ; CHECK-LABEL: test_builtin_trap
  call void @llvm.trap()
  ; CHECK: break

  ret void
}
