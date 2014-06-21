//===- IntrinsicsVectorProc.td - Defines VectorProc intrinsics ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the VectorProc-specific intrinsics.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

def v16i32_ptr_ty : LLVMPointerType<LLVMType<v16i32>>;

let TargetPrefix = "vectorproc" in {  // All intrinsics start with "llvm.vectorproc.".

def int_vp_read_control_reg : Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [],
	"llvm.vectorproc.__builtin_vp_read_control_reg">;
def int_vp_write_control_reg : Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], [],
	"llvm.vectorproc.__builtin_vp_write_control_reg">;

// Memory operations
def int_vp_gather_loadi : Intrinsic<[llvm_v16i32_ty], [llvm_v16i32_ty], 
	[IntrReadMem], "llvm.vectorproc.__builtin_vp_gather_loadi">;

def int_vp_gather_loadf : Intrinsic<[llvm_v16f32_ty], [llvm_v16i32_ty], 
	[IntrReadMem], "llvm.vectorproc.__builtin_vp_gather_loadf">;

def int_vp_gather_loadi_masked : Intrinsic<[llvm_v16i32_ty], [llvm_v16i32_ty, llvm_i32_ty], 
	[IntrReadMem], "llvm.vectorproc.__builtin_vp_gather_loadi_masked">;

def int_vp_gather_loadf_masked : Intrinsic<[llvm_v16f32_ty], [llvm_v16i32_ty, llvm_i32_ty], 
	[IntrReadMem], "llvm.vectorproc.__builtin_vp_gather_loadf_masked">;

def int_vp_scatter_storei : Intrinsic<[], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[], "llvm.vectorproc.__builtin_vp_scatter_storei">;

def int_vp_scatter_storef : Intrinsic<[], [llvm_v16i32_ty, llvm_v16f32_ty], 
	[], "llvm.vectorproc.__builtin_vp_scatter_storef">;

def int_vp_scatter_storei_masked : Intrinsic<[], [llvm_v16i32_ty, llvm_v16i32_ty, llvm_i32_ty], 
	[], "llvm.vectorproc.__builtin_vp_scatter_storei_masked">;

def int_vp_scatter_storef_masked : Intrinsic<[], [llvm_v16i32_ty, llvm_v16f32_ty, llvm_i32_ty], 
	[], "llvm.vectorproc.__builtin_vp_scatter_storef_masked">;

def int_vp_block_loadi_masked : Intrinsic<[llvm_v16i32_ty], [v16i32_ptr_ty, llvm_i32_ty], 
	[IntrReadArgMem], "llvm.vectorproc.__builtin_vp_block_loadi_masked">;

def int_vp_block_loadf_masked : Intrinsic<[llvm_v16f32_ty], [v16i32_ptr_ty, llvm_i32_ty], 
	[IntrReadArgMem], "llvm.vectorproc.__builtin_vp_block_loadf_masked">;

def int_vp_block_storei_masked : Intrinsic<[], [v16i32_ptr_ty, llvm_v16i32_ty, llvm_i32_ty], 
	[IntrReadWriteArgMem], "llvm.vectorproc.__builtin_vp_block_storei_masked">;

def int_vp_block_storef_masked : Intrinsic<[], [v16i32_ptr_ty, llvm_v16f32_ty, llvm_i32_ty], 
	[IntrReadWriteArgMem], "llvm.vectorproc.__builtin_vp_block_storef_masked">;

// The blend pattern is a pseudo-instruction used to encode masked operations
def int_vp_vector_mixi : Intrinsic<[llvm_v16i32_ty], [llvm_i32_ty, llvm_v16i32_ty, 
	llvm_v16i32_ty], [IntrNoMem], "llvm.vectorproc.__builtin_vp_vector_mixi">;

def int_vp_vector_mixf : Intrinsic<[llvm_v16f32_ty], [llvm_i32_ty, llvm_v16f32_ty,
	llvm_v16f32_ty], [IntrNoMem], "llvm.vectorproc.__builtin_vp_vector_mixf">;

// Shuffle vector elements
def int_vp_shufflei : Intrinsic<[llvm_v16i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty],
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_shufflei">;
def int_vp_shufflef : Intrinsic<[llvm_v16f32_ty], [llvm_v16f32_ty, llvm_v16i32_ty],
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_shufflef">;

// Vector Comparisions
def int_vp_mask_cmpi_ugt : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_ugt">;

def int_vp_mask_cmpi_uge : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_uge">;

def int_vp_mask_cmpi_ult : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_ult">;

def int_vp_mask_cmpi_ule : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_ule">;

def int_vp_mask_cmpi_sgt : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_sgt">;

def int_vp_mask_cmpi_sge : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_sge">;

def int_vp_mask_cmpi_slt : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_slt">;

def int_vp_mask_cmpi_sle : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_sle">;

def int_vp_mask_cmpi_eq : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_eq">;

def int_vp_mask_cmpi_ne : Intrinsic<[llvm_i32_ty], [llvm_v16i32_ty, llvm_v16i32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpi_ne">;

def int_vp_mask_cmpf_gt : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_gt">;

def int_vp_mask_cmpf_ge : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_ge">;

def int_vp_mask_cmpf_le : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_le">;

def int_vp_mask_cmpf_lt : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_lt">;

def int_vp_mask_cmpf_eq : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_eq">;

def int_vp_mask_cmpf_ne : Intrinsic<[llvm_i32_ty], [llvm_v16f32_ty, llvm_v16f32_ty], 
	[IntrNoMem], "llvm.vectorproc.__builtin_vp_mask_cmpf_ne">;
}

