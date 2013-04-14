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
// VectorProc DSP data types
def vectorproc_v2q15_ty: LLVMType<v2i16>;
def vectorproc_v4q7_ty: LLVMType<v4i8>;
def vectorproc_q31_ty: LLVMType<i32>;

let TargetPrefix = "vectorproc" in {  // All intrinsics start with "llvm.vectorproc.".

//===----------------------------------------------------------------------===//
// VectorProc DSP Rev 1

//===----------------------------------------------------------------------===//
// Addition/subtraction

def int_vectorproc_addu_qb : GCCBuiltin<"__builtin_vectorproc_addu_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_addu_s_qb : GCCBuiltin<"__builtin_vectorproc_addu_s_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_subu_qb : GCCBuiltin<"__builtin_vectorproc_subu_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], []>;
def int_vectorproc_subu_s_qb : GCCBuiltin<"__builtin_vectorproc_subu_s_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], []>;

def int_vectorproc_addq_ph : GCCBuiltin<"__builtin_vectorproc_addq_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_addq_s_ph : GCCBuiltin<"__builtin_vectorproc_addq_s_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_subq_ph : GCCBuiltin<"__builtin_vectorproc_subq_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_subq_s_ph : GCCBuiltin<"__builtin_vectorproc_subq_s_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;

def int_vectorproc_madd: GCCBuiltin<"__builtin_vectorproc_madd">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_maddu: GCCBuiltin<"__builtin_vectorproc_maddu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem, Commutative]>;

def int_vectorproc_msub: GCCBuiltin<"__builtin_vectorproc_msub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;
def int_vectorproc_msubu: GCCBuiltin<"__builtin_vectorproc_msubu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_vectorproc_addq_s_w: GCCBuiltin<"__builtin_vectorproc_addq_s_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [Commutative]>;
def int_vectorproc_subq_s_w: GCCBuiltin<"__builtin_vectorproc_subq_s_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], []>;

def int_vectorproc_addsc: GCCBuiltin<"__builtin_vectorproc_addsc">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [Commutative]>;
def int_vectorproc_addwc: GCCBuiltin<"__builtin_vectorproc_addwc">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [Commutative]>;

def int_vectorproc_modsub: GCCBuiltin<"__builtin_vectorproc_modsub">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrNoMem]>;

def int_vectorproc_raddu_w_qb: GCCBuiltin<"__builtin_vectorproc_raddu_w_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty], [IntrNoMem]>;

//===----------------------------------------------------------------------===//
// Absolute value

def int_vectorproc_absq_s_ph: GCCBuiltin<"__builtin_vectorproc_absq_s_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty], []>;
def int_vectorproc_absq_s_w: GCCBuiltin<"__builtin_vectorproc_absq_s_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty], []>;

//===----------------------------------------------------------------------===//
// Precision reduce/expand

def int_vectorproc_precrq_qb_ph: GCCBuiltin<"__builtin_vectorproc_precrq_qb_ph">,
  Intrinsic<[llvm_v4i8_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [IntrNoMem]>;
def int_vectorproc_precrqu_s_qb_ph: GCCBuiltin<"__builtin_vectorproc_precrqu_s_qb_ph">,
  Intrinsic<[llvm_v4i8_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_precrq_ph_w: GCCBuiltin<"__builtin_vectorproc_precrq_ph_w">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [IntrNoMem]>;
def int_vectorproc_precrq_rs_ph_w: GCCBuiltin<"__builtin_vectorproc_precrq_rs_ph_w">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_q31_ty, vectorproc_q31_ty], []>;
def int_vectorproc_preceq_w_phl: GCCBuiltin<"__builtin_vectorproc_preceq_w_phl">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_v2q15_ty], [IntrNoMem]>;
def int_vectorproc_preceq_w_phr: GCCBuiltin<"__builtin_vectorproc_preceq_w_phr">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_v2q15_ty], [IntrNoMem]>;
def int_vectorproc_precequ_ph_qbl: GCCBuiltin<"__builtin_vectorproc_precequ_ph_qbl">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_precequ_ph_qbr: GCCBuiltin<"__builtin_vectorproc_precequ_ph_qbr">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_precequ_ph_qbla: GCCBuiltin<"__builtin_vectorproc_precequ_ph_qbla">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_precequ_ph_qbra: GCCBuiltin<"__builtin_vectorproc_precequ_ph_qbra">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_preceu_ph_qbl: GCCBuiltin<"__builtin_vectorproc_preceu_ph_qbl">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_preceu_ph_qbr: GCCBuiltin<"__builtin_vectorproc_preceu_ph_qbr">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_preceu_ph_qbla: GCCBuiltin<"__builtin_vectorproc_preceu_ph_qbla">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_preceu_ph_qbra: GCCBuiltin<"__builtin_vectorproc_preceu_ph_qbra">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty], [IntrNoMem]>;

//===----------------------------------------------------------------------===//
// Shift

def int_vectorproc_shll_qb: GCCBuiltin<"__builtin_vectorproc_shll_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_i32_ty], []>;
def int_vectorproc_shrl_qb: GCCBuiltin<"__builtin_vectorproc_shrl_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shll_ph: GCCBuiltin<"__builtin_vectorproc_shll_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, llvm_i32_ty], []>;
def int_vectorproc_shll_s_ph: GCCBuiltin<"__builtin_vectorproc_shll_s_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, llvm_i32_ty], []>;
def int_vectorproc_shra_ph: GCCBuiltin<"__builtin_vectorproc_shra_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shra_r_ph: GCCBuiltin<"__builtin_vectorproc_shra_r_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shll_s_w: GCCBuiltin<"__builtin_vectorproc_shll_s_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, llvm_i32_ty], []>;
def int_vectorproc_shra_r_w: GCCBuiltin<"__builtin_vectorproc_shra_r_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shilo: GCCBuiltin<"__builtin_vectorproc_shilo">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty], [IntrNoMem]>;

//===----------------------------------------------------------------------===//
// Multiplication

def int_vectorproc_muleu_s_ph_qbl: GCCBuiltin<"__builtin_vectorproc_muleu_s_ph_qbl">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_muleu_s_ph_qbr: GCCBuiltin<"__builtin_vectorproc_muleu_s_ph_qbr">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_v4i8_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_mulq_rs_ph: GCCBuiltin<"__builtin_vectorproc_mulq_rs_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_muleq_s_w_phl: GCCBuiltin<"__builtin_vectorproc_muleq_s_w_phl">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_muleq_s_w_phr: GCCBuiltin<"__builtin_vectorproc_muleq_s_w_phr">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_mulsaq_s_w_ph: GCCBuiltin<"__builtin_vectorproc_mulsaq_s_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_maq_s_w_phl: GCCBuiltin<"__builtin_vectorproc_maq_s_w_phl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_maq_s_w_phr: GCCBuiltin<"__builtin_vectorproc_maq_s_w_phr">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_maq_sa_w_phl: GCCBuiltin<"__builtin_vectorproc_maq_sa_w_phl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_maq_sa_w_phr: GCCBuiltin<"__builtin_vectorproc_maq_sa_w_phr">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_mult: GCCBuiltin<"__builtin_vectorproc_mult">,
  Intrinsic<[llvm_i64_ty], [llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_multu: GCCBuiltin<"__builtin_vectorproc_multu">,
  Intrinsic<[llvm_i64_ty], [llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem, Commutative]>;

//===----------------------------------------------------------------------===//
// Dot product with accumulate/subtract

def int_vectorproc_dpau_h_qbl: GCCBuiltin<"__builtin_vectorproc_dpau_h_qbl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem]>;
def int_vectorproc_dpau_h_qbr: GCCBuiltin<"__builtin_vectorproc_dpau_h_qbr">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem]>;
def int_vectorproc_dpsu_h_qbl: GCCBuiltin<"__builtin_vectorproc_dpsu_h_qbl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem]>;
def int_vectorproc_dpsu_h_qbr: GCCBuiltin<"__builtin_vectorproc_dpsu_h_qbr">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem]>;
def int_vectorproc_dpaq_s_w_ph: GCCBuiltin<"__builtin_vectorproc_dpaq_s_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_dpsq_s_w_ph: GCCBuiltin<"__builtin_vectorproc_dpsq_s_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_dpaq_sa_l_w: GCCBuiltin<"__builtin_vectorproc_dpaq_sa_l_w">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_q31_ty, vectorproc_q31_ty], []>;
def int_vectorproc_dpsq_sa_l_w: GCCBuiltin<"__builtin_vectorproc_dpsq_sa_l_w">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_q31_ty, vectorproc_q31_ty], []>;

//===----------------------------------------------------------------------===//
// Comparison

def int_vectorproc_cmpu_eq_qb: GCCBuiltin<"__builtin_vectorproc_cmpu_eq_qb">,
  Intrinsic<[], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpu_lt_qb: GCCBuiltin<"__builtin_vectorproc_cmpu_lt_qb">,
  Intrinsic<[], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpu_le_qb: GCCBuiltin<"__builtin_vectorproc_cmpu_le_qb">,
  Intrinsic<[], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpgu_eq_qb: GCCBuiltin<"__builtin_vectorproc_cmpgu_eq_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpgu_lt_qb: GCCBuiltin<"__builtin_vectorproc_cmpgu_lt_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpgu_le_qb: GCCBuiltin<"__builtin_vectorproc_cmpgu_le_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmp_eq_ph: GCCBuiltin<"__builtin_vectorproc_cmp_eq_ph">,
  Intrinsic<[], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_cmp_lt_ph: GCCBuiltin<"__builtin_vectorproc_cmp_lt_ph">,
  Intrinsic<[], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_cmp_le_ph: GCCBuiltin<"__builtin_vectorproc_cmp_le_ph">,
  Intrinsic<[], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;

//===----------------------------------------------------------------------===//
// Extracting

def int_vectorproc_extr_s_h: GCCBuiltin<"__builtin_vectorproc_extr_s_h">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;
def int_vectorproc_extr_w: GCCBuiltin<"__builtin_vectorproc_extr_w">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;
def int_vectorproc_extr_rs_w: GCCBuiltin<"__builtin_vectorproc_extr_rs_w">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;
def int_vectorproc_extr_r_w: GCCBuiltin<"__builtin_vectorproc_extr_r_w">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;
def int_vectorproc_extp: GCCBuiltin<"__builtin_vectorproc_extp">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;
def int_vectorproc_extpdp: GCCBuiltin<"__builtin_vectorproc_extpdp">,
  Intrinsic<[llvm_i32_ty], [llvm_i64_ty, llvm_i32_ty], []>;

//===----------------------------------------------------------------------===//
// Misc

def int_vectorproc_wrdsp: GCCBuiltin<"__builtin_vectorproc_wrdsp">,
  Intrinsic<[], [llvm_i32_ty, llvm_i32_ty], []>;
def int_vectorproc_rddsp: GCCBuiltin<"__builtin_vectorproc_rddsp">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrReadMem]>;

def int_vectorproc_insv: GCCBuiltin<"__builtin_vectorproc_insv">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty], [IntrReadMem]>;
def int_vectorproc_bitrev: GCCBuiltin<"__builtin_vectorproc_bitrev">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_vectorproc_packrl_ph: GCCBuiltin<"__builtin_vectorproc_packrl_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [IntrNoMem]>;

def int_vectorproc_repl_qb: GCCBuiltin<"__builtin_vectorproc_repl_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_repl_ph: GCCBuiltin<"__builtin_vectorproc_repl_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [llvm_i32_ty], [IntrNoMem]>;

def int_vectorproc_pick_qb: GCCBuiltin<"__builtin_vectorproc_pick_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [IntrReadMem]>;
def int_vectorproc_pick_ph: GCCBuiltin<"__builtin_vectorproc_pick_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [IntrReadMem]>;

def int_vectorproc_mthlip: GCCBuiltin<"__builtin_vectorproc_mthlip">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i32_ty], []>;

def int_vectorproc_bposge32: GCCBuiltin<"__builtin_vectorproc_bposge32">,
  Intrinsic<[llvm_i32_ty], [], [IntrReadMem]>;

def int_vectorproc_lbux: GCCBuiltin<"__builtin_vectorproc_lbux">,
  Intrinsic<[llvm_i32_ty], [llvm_ptr_ty, llvm_i32_ty], [IntrReadArgMem]>;
def int_vectorproc_lhx: GCCBuiltin<"__builtin_vectorproc_lhx">,
  Intrinsic<[llvm_i32_ty], [llvm_ptr_ty, llvm_i32_ty], [IntrReadArgMem]>;
def int_vectorproc_lwx: GCCBuiltin<"__builtin_vectorproc_lwx">,
  Intrinsic<[llvm_i32_ty], [llvm_ptr_ty, llvm_i32_ty], [IntrReadArgMem]>;

//===----------------------------------------------------------------------===//
// VectorProc DSP Rev 2

def int_vectorproc_absq_s_qb: GCCBuiltin<"__builtin_vectorproc_absq_s_qb">,
  Intrinsic<[vectorproc_v4q7_ty], [vectorproc_v4q7_ty], []>;

def int_vectorproc_addqh_ph: GCCBuiltin<"__builtin_vectorproc_addqh_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_addqh_r_ph: GCCBuiltin<"__builtin_vectorproc_addqh_r_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_addqh_w: GCCBuiltin<"__builtin_vectorproc_addqh_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_addqh_r_w: GCCBuiltin<"__builtin_vectorproc_addqh_r_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty],
            [IntrNoMem, Commutative]>;

def int_vectorproc_addu_ph: GCCBuiltin<"__builtin_vectorproc_addu_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], [Commutative]>;
def int_vectorproc_addu_s_ph: GCCBuiltin<"__builtin_vectorproc_addu_s_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], [Commutative]>;

def int_vectorproc_adduh_qb: GCCBuiltin<"__builtin_vectorproc_adduh_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem, Commutative]>;
def int_vectorproc_adduh_r_qb: GCCBuiltin<"__builtin_vectorproc_adduh_r_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty],
            [IntrNoMem, Commutative]>;

def int_vectorproc_append: GCCBuiltin<"__builtin_vectorproc_append">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]>;
def int_vectorproc_balign: GCCBuiltin<"__builtin_vectorproc_balign">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]>;

def int_vectorproc_cmpgdu_eq_qb: GCCBuiltin<"__builtin_vectorproc_cmpgdu_eq_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpgdu_lt_qb: GCCBuiltin<"__builtin_vectorproc_cmpgdu_lt_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;
def int_vectorproc_cmpgdu_le_qb: GCCBuiltin<"__builtin_vectorproc_cmpgdu_le_qb">,
  Intrinsic<[llvm_i32_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [Commutative]>;

def int_vectorproc_dpa_w_ph: GCCBuiltin<"__builtin_vectorproc_dpa_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v2i16_ty, llvm_v2i16_ty],
            [IntrNoMem]>;
def int_vectorproc_dps_w_ph: GCCBuiltin<"__builtin_vectorproc_dps_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v2i16_ty, llvm_v2i16_ty],
            [IntrNoMem]>;

def int_vectorproc_dpaqx_s_w_ph: GCCBuiltin<"__builtin_vectorproc_dpaqx_s_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_dpaqx_sa_w_ph: GCCBuiltin<"__builtin_vectorproc_dpaqx_sa_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_dpax_w_ph: GCCBuiltin<"__builtin_vectorproc_dpax_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v2i16_ty, llvm_v2i16_ty],
            [IntrNoMem]>;
def int_vectorproc_dpsx_w_ph: GCCBuiltin<"__builtin_vectorproc_dpsx_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v2i16_ty, llvm_v2i16_ty],
            [IntrNoMem]>;
def int_vectorproc_dpsqx_s_w_ph: GCCBuiltin<"__builtin_vectorproc_dpsqx_s_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;
def int_vectorproc_dpsqx_sa_w_ph: GCCBuiltin<"__builtin_vectorproc_dpsqx_sa_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, vectorproc_v2q15_ty, vectorproc_v2q15_ty], []>;

def int_vectorproc_mul_ph: GCCBuiltin<"__builtin_vectorproc_mul_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], [Commutative]>;
def int_vectorproc_mul_s_ph: GCCBuiltin<"__builtin_vectorproc_mul_s_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], [Commutative]>;

def int_vectorproc_mulq_rs_w: GCCBuiltin<"__builtin_vectorproc_mulq_rs_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [Commutative]>;
def int_vectorproc_mulq_s_ph: GCCBuiltin<"__builtin_vectorproc_mulq_s_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [Commutative]>;
def int_vectorproc_mulq_s_w: GCCBuiltin<"__builtin_vectorproc_mulq_s_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [Commutative]>;
def int_vectorproc_mulsa_w_ph: GCCBuiltin<"__builtin_vectorproc_mulsa_w_ph">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_v2i16_ty, llvm_v2i16_ty],
            [IntrNoMem]>;

def int_vectorproc_precr_qb_ph: GCCBuiltin<"__builtin_vectorproc_precr_qb_ph">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v2i16_ty, llvm_v2i16_ty], []>;
def int_vectorproc_precr_sra_ph_w: GCCBuiltin<"__builtin_vectorproc_precr_sra_ph_w">,
  Intrinsic<[llvm_v2i16_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;
def int_vectorproc_precr_sra_r_ph_w: GCCBuiltin<"__builtin_vectorproc_precr_sra_r_ph_w">,
  Intrinsic<[llvm_v2i16_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
            [IntrNoMem]>;

def int_vectorproc_prepend: GCCBuiltin<"__builtin_vectorproc_prepend">,
  Intrinsic<[llvm_i32_ty], [llvm_i32_ty, llvm_i32_ty, llvm_i32_ty],
  [IntrNoMem]>;

def int_vectorproc_shra_qb: GCCBuiltin<"__builtin_vectorproc_shra_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shra_r_qb: GCCBuiltin<"__builtin_vectorproc_shra_r_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_i32_ty], [IntrNoMem]>;
def int_vectorproc_shrl_ph: GCCBuiltin<"__builtin_vectorproc_shrl_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_i32_ty], [IntrNoMem]>;

def int_vectorproc_subqh_ph: GCCBuiltin<"__builtin_vectorproc_subqh_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [IntrNoMem]>;
def int_vectorproc_subqh_r_ph: GCCBuiltin<"__builtin_vectorproc_subqh_r_ph">,
  Intrinsic<[vectorproc_v2q15_ty], [vectorproc_v2q15_ty, vectorproc_v2q15_ty], [IntrNoMem]>;
def int_vectorproc_subqh_w: GCCBuiltin<"__builtin_vectorproc_subqh_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [IntrNoMem]>;
def int_vectorproc_subqh_r_w: GCCBuiltin<"__builtin_vectorproc_subqh_r_w">,
  Intrinsic<[vectorproc_q31_ty], [vectorproc_q31_ty, vectorproc_q31_ty], [IntrNoMem]>;

def int_vectorproc_subu_ph: GCCBuiltin<"__builtin_vectorproc_subu_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], []>;
def int_vectorproc_subu_s_ph: GCCBuiltin<"__builtin_vectorproc_subu_s_ph">,
  Intrinsic<[llvm_v2i16_ty], [llvm_v2i16_ty, llvm_v2i16_ty], []>;

def int_vectorproc_subuh_qb: GCCBuiltin<"__builtin_vectorproc_subuh_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [IntrNoMem]>;
def int_vectorproc_subuh_r_qb: GCCBuiltin<"__builtin_vectorproc_subuh_r_qb">,
  Intrinsic<[llvm_v4i8_ty], [llvm_v4i8_ty, llvm_v4i8_ty], [IntrNoMem]>;
}
