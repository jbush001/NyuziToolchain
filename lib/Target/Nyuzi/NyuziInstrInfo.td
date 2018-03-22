//===-- NyuziInstrInfo.td - Target Description for Nyuzi Target -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the Nyuzi instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "NyuziInstrFormats.td"

//////////////////////////////////////////////////////////////////
// Arithmetic
//////////////////////////////////////////////////////////////////

let isCommutable = 1 in {
    defm OR     : TwoOpIntArith<"or", or, 0x00>;
    defm AND    : TwoOpIntArith<"and", and, 0x01>;
    defm XOR    : TwoOpIntArith<"xor", xor, 0x03>;
    defm ADDI   : TwoOpIntArith<"add_i", add, 0x05>;
    defm MULLI  : TwoOpIntArith<"mull_i", mul, 0x07>;
    defm MULHU  : TwoOpIntArith<"mulh_u", mulhu, 0x08>;
    defm MULHI  : TwoOpIntArith<"mulh_i", mulhs, 0x1f>;
    defm ADDF   : TwoOpFloatArith<"add_f", fadd, 0x20>;
    defm MULF   : TwoOpFloatArith<"mul_f", fmul, 0x22>;
}

defm SUBI   : TwoOpIntArith<"sub_i", sub, 0x06>;
defm SRA    : TwoOpIntArith<"ashr", sra, 0x09>;
defm SRL    : TwoOpIntArith<"shr", srl, 0x0a>;
defm SLL    : TwoOpIntArith<"shl", shl, 0x0b>;
defm CLZ    : OneOpIntArith<"clz", ctlz, 0x0c>;
defm CTZ    : OneOpIntArith<"ctz", cttz, 0x0e>;
defm SUBF   : TwoOpFloatArith<"sub_f", fsub, 0x21>;
defm RECIP  : OneOpFloatArith<"reciprocal", reciprocal, 0x1c>;

// XXX there must be some way to generate SEXT8/SEXT16/SITOF/FTOSI using
// a multipattern instead of all of the duplication below. Need a way to
// parameterize the operand types
//
// XXX The instruction matching patterns for masked and vector/scalar versions
// of sext8/sext16 are commented out as they cause a type inference
// contradiction in TableGen. It's not clear why only these instructions
// cause the issue. It's not a big deal, the compiler will generate a few
// extra instructions to transfer to an intermediate register. These are rare
// enough that the performance impact is negligible.

def SEXT8SS : FormatRUnmaskedOneOpInst<
  (outs GPR32:$dest),
  (ins GPR32:$src2),
  "sext_8 $dest, $src2",
  [(set i32:$dest, (sext_inreg i32:$src2, i8))],
  0x1d,
  FmtR_SSS,
  II_INT>;

def SEXT8VS : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins GPR32:$src2),
  "sext_8 $dest, $src2",
  [/*(set v16i32:$dest, (sext_inreg (splat i32:$src2), i8))*/],
  0x1d,
  FmtR_VVS,
  II_INT>;

def SEXT8VV : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins VR512:$src2),
  "sext_8 $dest, $src2",
  [(set v16i32:$dest, (sext_inreg v16i32:$src2, v16i8))],
  0x1d,
  FmtR_VVV,
  II_INT>;

let Constraints = "$dest = $oldvalue" in {
  def SEXT8VVM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
    "sext_8_mask $dest, $mask, $src2",
    [/*(set v16i32:$dest, (vselect v16i1:$mask, (sext_inreg v16i32:$src2, i8), v16i32:$oldvalue))*/],
    0x1d,
    FmtR_VVVM,
    II_INT>;

  def SEXT8VSM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
    "sext_8_mask $dest, $mask, $src2",
    [/*(set v16i32:$dest, (vselect v16i1:$mask, (sext_inreg (splat i32:$src2), i8), v16i32:$oldvalue))*/],
    0x1d,
    FmtR_VVSM,
    II_INT>;
}

def SEXT16SS : FormatRUnmaskedOneOpInst<
  (outs GPR32:$dest),
  (ins GPR32:$src2),
  "sext_16 $dest, $src2",
  [(set i32:$dest, (sext_inreg i32:$src2, i16))],
  0x1e,
  FmtR_SSS,
  II_INT>;

def SEXT16VS : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins GPR32:$src2),
  "sext_16 $dest, $src2",
  [/*(set v16i32:$dest, (sext_inreg (splat i32:$src2), i16))*/],
  0x1e,
  FmtR_VVS,
  II_INT>;

def SEXT16VV : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins VR512:$src2),
  "sext_16 $dest, $src2",
  [(set v16i32:$dest, (sext_inreg v16i32:$src2, v16i16))],
  0x1e,
  FmtR_VVV,
  II_INT>;

let Constraints = "$dest = $oldvalue" in {
  def SEXT16VVM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
    "sext_16_mask $dest, $mask, $src2",
    [/*(set v16i32:$dest, (vselect v16i1:$mask, (sext_inreg v16i32:$src2, i16), v16i32:$oldvalue))*/],
    0x1e,
    FmtR_VVVM,
    II_INT>;

  def SEXT16VSM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
    "sext_16_mask $dest, $mask, $src2",
    [/*(set v16i32:$dest, (vselect v16i1:$mask, (sext_inreg (splat i32:$src2), i16),
      VR512:$oldvalue))*/],
    0x1e,
    FmtR_VVSM,
    II_INT>;
}

def SITOFSS : FormatRUnmaskedOneOpInst<
  (outs GPR32:$dest),
  (ins GPR32:$src2),
  "itof $dest, $src2",
  [(set f32:$dest, (sint_to_fp i32:$src2))],
  0x2a,
  FmtR_SSS,
  II_FLOAT>;

def SITOFVS : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins GPR32:$src2),
  "itof $dest, $src2",
  [(set v16f32:$dest, (sint_to_fp (splat i32:$src2)))],
  0x2a,
  FmtR_VVS,
  II_FLOAT>;

def SITOFVV : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins VR512:$src2),
  "itof $dest, $src2",
  [(set v16f32:$dest, (sint_to_fp v16i32:$src2))],
  0x2a,
  FmtR_VVV,
  II_FLOAT>;

let Constraints = "$dest = $oldvalue" in {
  def SITOFVSM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
    "itof_mask $dest, $mask, $src2",
    [(set v16f32:$dest, (vselect v16i1:$mask, (sint_to_fp (splat i32:$src2)),
      v16f32:$oldvalue))],
    0x2a,
    FmtR_VVSM,
    II_FLOAT>;

  def SITOFVVM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
    "itof_mask $dest, $mask, $src2",
    [(set v16f32:$dest, (vselect v16i1:$mask, (sint_to_fp v16i32:$src2), v16f32:$oldvalue))],
    0x2a,
    FmtR_VVVM,
    II_FLOAT>;
}

def FTOIISS : FormatRUnmaskedOneOpInst<
  (outs GPR32:$dest),
  (ins GPR32:$src2),
  "ftoi $dest, $src2",
  [(set i32:$dest, (fp_to_sint f32:$src2))],
  0x1b,
  FmtR_SSS,
  II_FLOAT>;

def FTOSIVS : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins GPR32:$src2),
  "ftoi $dest, $src2",
  [(set v16i32:$dest, (fp_to_sint (splat f32:$src2)))],
  0x1b,
  FmtR_VVS,
  II_FLOAT>;

def FTOSIVV : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins VR512:$src2),
  "ftoi $dest, $src2",
  [(set v16i32:$dest, (fp_to_sint v16f32:$src2))],
  0x1b,
  FmtR_VVV,
  II_FLOAT>;

let Constraints = "$dest = $oldvalue" in {
  def FTOSIVSM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
    "ftoi_mask $dest, $mask, $src2",
    [(set v16i32:$dest, (vselect v16i1:$mask, (fp_to_sint (splat f32:$src2)),
      v16i32:$oldvalue))],
    0x1b,
    FmtR_VVSM,
    II_FLOAT>;

  def FTOSIVVM : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
    "ftoi_mask $dest, $mask, $src2",
    [(set v16i32:$dest, (vselect v16i1:$mask, (fp_to_sint v16f32:$src2), v16i32:$oldvalue))],
    0x1b,
    FmtR_VVVM,
    II_FLOAT>;
}

defm SGTSI : IntCompareInst<"cmpgt_i", SETGT, 0x12>;
defm SGESI : IntCompareInst<"cmpge_i", SETGE, 0x13>;
defm SLTSI : IntCompareInst<"cmplt_i", SETLT, 0x14>;
defm SLESI : IntCompareInst<"cmple_i", SETLE, 0x15>;
defm SEQSI : IntCompareInst<"cmpeq_i", SETEQ, 0x10>;
defm SNESI : IntCompareInst<"cmpne_i", SETNE, 0x11>;
defm SGTUI : IntCompareInst<"cmpgt_u", SETUGT, 0x16>;
defm SGEUI : IntCompareInst<"cmpge_u", SETUGE, 0x17>;
defm SLTUI : IntCompareInst<"cmplt_u", SETULT, 0x18>;
defm SLEUI : IntCompareInst<"cmple_u", SETULE, 0x19>;

// Float comparisons are lowered to custom SDNodes so that unsupported
// comparisons can be turned into legal comparisons plus some logical
// operations, which may lead to an infinite loop
def FloatCompareType: SDTypeProfile<1, 2, [
  SDTCisInt<0>, SDTCisFP<1>, SDTCisSameAs<1, 2>
]>;
def FGT: SDNode<"NyuziISD::FGT", FloatCompareType>;
def FGE: SDNode<"NyuziISD::FGE", FloatCompareType>;
def FLT: SDNode<"NyuziISD::FLT", FloatCompareType>;
def FLE: SDNode<"NyuziISD::FLE", FloatCompareType>;
def FEQ: SDNode<"NyuziISD::FEQ", FloatCompareType>;
def FNE: SDNode<"NyuziISD::FNE", FloatCompareType>;

defm SGTFO : FloatCompareInst<"cmpgt", FGT, 0x2c>;
defm SGEFO : FloatCompareInst<"cmpge", FGE, 0x2d>;
defm SLTFO : FloatCompareInst<"cmplt", FLT, 0x2e>;
defm SLEFO : FloatCompareInst<"cmple", FLE, 0x2f>;
defm SEQFO : FloatCompareInst<"cmpeq", FEQ, 0x30>;
defm SNEFO : FloatCompareInst<"cmpne", FNE, 0x31>;

// Mask operations (register-register)
def : Pat<(or v16i1:$src1, v16i1:$src2), (ORSSS v16i1:$src1, v16i1:$src2)>;
def : Pat<(and v16i1:$src1, v16i1:$src2), (ANDSSS v16i1:$src1, v16i1:$src2)>;
def : Pat<(xor v16i1:$src1, v16i1:$src2), (XORSSS v16i1:$src1, v16i1:$src2)>;
// Mask operations (register-immediate)
def : Pat<(or v16i1:$src1, (mask_from_int simm14:$src2)), (ORSSI v16i1:$src1, simm14:$src2)>;
def : Pat<(and v16i1:$src1, (mask_from_int simm14:$src2)), (ANDSSI v16i1:$src1, simm14:$src2)>;
def : Pat<(xor v16i1:$src1, (mask_from_int simm14:$src2)), (XORSSI v16i1:$src1, simm14:$src2)>;


def GET_LANEI : FormatRUnmaskedTwoOpInst<
  (outs GPR32:$dest),
  (ins VR512:$src1, GPR32:$src2),
  "getlane $dest, $src1, $src2",  // XXX this isn't a good name, replace
  [(set i32:$dest, (extractelt v16i32:$src1, i32:$src2))],
  0x1a,
  FmtR_VVS,
  II_INT>;

def GET_LANEIimm : FormatIUnmaskedInst<
  (outs GPR32:$dest),
  (ins VR512:$src1, SIMM14OP:$imm),
  "getlane $dest, $src1, $imm",
  [(set i32:$dest, (extractelt v16i32:$src1, simm14:$imm))],
  0x1a,
  FmtI_V,
  II_INT>;

def : Pat<(extractelt v16f32:$src1, i32:$src2),
  (GET_LANEI v16f32:$src1, i32:$src2)>;
def : Pat<(extractelt v16f32:$src1, simm14:$imm),
  (GET_LANEIimm v16f32:$src1, imm:$imm)>;

def SHUFFLEI : FormatRUnmaskedTwoOpInst<
  (outs VR512:$dest),
  (ins VR512:$src1, VR512:$src2),
  "shuffle $dest, $src1, $src2",
  [(set v16i32:$dest, (int_nyuzi_shufflei v16i32:$src1, v16i32:$src2))],
  0x0d,
  FmtR_VVV,
  II_INT>;

let Constraints = "$dest = $oldvalue" in {
  def SHUFFLEI_MASK : FormatRMaskedTwoOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src1, VR512:$src2, VR512:$oldvalue),
    "shuffle_mask $dest, $mask, $src1, $src2",
    [(set v16i32:$dest, (vselect v16i1:$mask, (int_nyuzi_shufflei v16i32:$src1,
      v16i32:$src2), v16i32:$oldvalue))],
    0x0d,
    FmtR_VVVM,
    II_INT>;
}


// Floating point shuffle forms
def : Pat<(int_nyuzi_shufflef v16f32:$src1, v16i32:$src2),
  (SHUFFLEI v16f32:$src1, v16i32:$src2)>;
def : Pat<(vselect v16i1:$mask, (int_nyuzi_shufflef v16f32:$src1, v16i32:$src2),
  v16f32:$oldvalue),
  (SHUFFLEI_MASK v16i1:$mask, v16f32:$src1, v16i32:$src2, v16f32:$oldvalue)>;

def MOVESS : FormatRUnmaskedOneOpInst<
  (outs GPR32:$dest),
  (ins GPR32:$src2),
  "move $dest, $src2",
  [],  // assembler only form for register-to-register moves
  0xf,
  FmtR_SSS,
  II_INT>;

// v16i1<->i32 type punning. Lowered to a generic COPY MachineInst,
// which is transparent to the rest of LLVM and can be optimized.
def : Pat<(i32 (mask_to_int v16i1:$src)), (COPY $src)>;
def : Pat<(v16i1 (mask_from_int i32:$src)), (COPY $src)>;

// This should only be invoked for types that will fit in the immediate field
// of the instruction.  The lowering code will transform other types into
// constant pool loads.
def MOVESimm :  NyuziInstruction<
  (outs GPR32:$dest),
  (ins SIMM14OP:$imm),
  "move $dest, $imm",
  [(set i32:$dest, simm14:$imm)],
  II_INT> {
  bits <5> dest;
  bits <14> imm;

  let Inst{30-29} = FmtI_S.Value;
  let Inst{28-24} = 0xf;  // MOVE
  let Inst{9-5} = dest;
  let Inst{23-10} = imm;
}

def MOVEVSI : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins GPR32:$src2),
  "move $dest, $src2",
  [(set v16i32:$dest, (splat i32:$src2))],
  0xf,
  FmtR_VVS,
  II_INT>;

def MOVEVimm : FormatIUnmaskedInst<
  (outs VR512:$dest),
  (ins SIMM14OP:$imm),
  "move $dest, $imm",
  [(set v16i32:$dest, (splat simm14:$imm))],
  0xf,
  FmtI_V,
  II_INT> {
  let src1 = 0;
}

def : Pat<(v16f32 (splat f32:$src2)), (MOVEVSI f32:$src2)>;

def MOVEVV : FormatRUnmaskedOneOpInst<
  (outs VR512:$dest),
  (ins VR512:$src2),
  "move $dest, $src2",
  [],
  0xf,
  FmtR_VVV,
  II_INT>;

// Predicated
let Constraints = "$dest = $oldvalue" in {
  def MOVEVVMI : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
    "move_mask $dest, $mask, $src2",
    [(set v16i32:$dest, (vselect v16i1:$mask, v16i32:$src2, v16i32:$oldvalue))],
    0xf,
    FmtR_VVVM,
    II_INT>;

  def MOVEVVMIimm : FormatIMaskedInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, SIMM9OP:$imm, VR512:$oldvalue),
    "move_mask $dest, $mask, $imm",
    [(set v16i32:$dest, (vselect v16i1:$mask, (splat simm9:$imm), v16i32:$oldvalue))],
    0xf,
    FmtI_VM,
    II_INT>;

  def MOVEVSMI : FormatRMaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
    "move_mask $dest, $mask, $src2",
    [(set v16i32:$dest, (vselect v16i1:$mask, (splat i32:$src2), v16i32:$oldvalue))],
    0xf,
    FmtR_VVSM,
    II_INT>;
}

def : Pat<(vselect v16i1:$mask, v16f32:$src2, v16f32:$oldvalue),
  (MOVEVVMI v16i1:$mask, v16f32:$src2, v16f32:$oldvalue)>;
def : Pat<(vselect v16i1:$mask, (splat f32:$src2), v16f32:$oldvalue),
  (MOVEVSMI v16i1:$mask, f32:$src2, v16f32:$oldvalue)>;

def MOVEHI : NyuziInstruction<
  (outs GPR32:$dest),
  (ins SIMM19OP:$imm),
  "movehi $dest, $imm",
  [],
  II_INT> {

  bits<19> imm;
  bits<5> dest;

  let Inst{31} = 0;
  let Inst{30-29} = FmtI_EXT.Value;
  let Inst{28-24} = 15; // Move
  let Inst{23-10} = imm{18-5};
  let Inst{9-5} = dest;
  let Inst{4-0} = imm{4-0};
}

//////////////////////////////////////////////////////////////////
// Memory Access (Format C)
//////////////////////////////////////////////////////////////////

// Scalar
let mayLoad = 1 in {
  def LBS : ScalarLoadInst<"s8", sextloadi8, FmtM_Byte_Signed>;
  def LBU : ScalarLoadInst<"u8", zextloadi8, FmtM_Byte_Unsigned>;
  def LSS : ScalarLoadInst<"s16", sextloadi16, FmtM_Short_Signed>;
  def LSU : ScalarLoadInst<"u16", zextloadi16, FmtM_Short_Unsigned>;
  def LW : ScalarLoadInst<"32", load, FmtM_Word>;
  def LOAD_SYNC : FormatMUnmaskedInst<
    (outs GPR32:$srcDest),
    (ins MEMS15:$addr),
    "load_sync $srcDest, $addr",
    [],
    FmtM_Sync,
    1>;

  def BLOCK_LOADI : FormatMUnmaskedInst<
    (outs VR512:$srcDest),
    (ins MEMS15:$addr),
    "load_v $srcDest, $addr",
    [(set v16i32:$srcDest, (load ADDRri:$addr))],
    FmtM_Block,
    1>;

  def INT_BLOCK_LOADI_MASKED : FormatMMaskedInst<
    (outs VR512:$srcDest),
    (ins MEMS10:$addr, GPR32:$mask),
    "load_v_mask $srcDest, $mask, $addr",
    [],
    FmtM_BlockMasked,
    1>;


  def INT_GATHER_LOADI : FormatMUnmaskedInst<
    (outs VR512:$srcDest),
    (ins MEMV15:$addr),
    "load_gath $srcDest, $addr",
    [(set v16i32:$srcDest, (int_nyuzi_gather_loadi VADDRri:$addr))], FmtM_ScGath,
    1>;

  def INT_GATHER_LOADI_MASKED : FormatMMaskedInst<
    (outs VR512:$srcDest),
    (ins MEMV10:$addr, GPR32:$mask),
    "load_gath_mask $srcDest, $mask, $addr",
    [(set v16i32:$srcDest, (int_nyuzi_gather_loadi_masked VADDRri:$addr, v16i1:$mask))],
    FmtM_ScGathMasked,
    1>;
}

def : Pat<(i32 (zextloadi1 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi1 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi8 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi16 ADDRri:$addr)), (LSS ADDRri:$addr)>;
def : Pat<(f32 (load ADDRri:$addr)), (LW ADDRri:$addr)>;
def : Pat<(v16f32 (load ADDRri:$addr)), (BLOCK_LOADI ADDRri:$addr)>;
def : Pat<(int_nyuzi_gather_loadf VADDRri:$addr), (INT_GATHER_LOADI VADDRri:$addr)>;
def : Pat<(int_nyuzi_gather_loadf_masked VADDRri:$addr, v16i1:$mask),
  (INT_GATHER_LOADI_MASKED VADDRri:$addr, v16i1:$mask)>;
def : Pat<(v16i1 (load ADDRri:$addr)), (LSU ADDRri:$addr)>;

let mayStore = 1 in {
  def SB : ScalarStoreInst<"8", truncstorei8, FmtM_Byte_Signed>;
  def SS : ScalarStoreInst<"16", truncstorei16, FmtM_Short_Signed>;
  def SW : ScalarStoreInst<"32", store, FmtM_Word>;
  def STORE_SYNC : FormatMUnmaskedInst<
    (outs GPR32:$result),
    (ins GPR32:$srcDest, MEMS15:$addr),
    "store_sync $srcDest, $addr  ",
    [],
    FmtM_Sync,
    0> {
    let Constraints = "$result = $srcDest";
  }

  def BLOCK_STOREI : FormatMUnmaskedInst<
    (outs),
    (ins VR512:$srcDest, MEMS15:$addr),
    "store_v $srcDest, $addr",
    [(store v16i32:$srcDest, ADDRri:$addr)],
    FmtM_Block,
    0>;

  def INT_BLOCK_STOREI_MASKED : FormatMMaskedInst<
    (outs),
    (ins VR512:$srcDest, MEMS10:$addr, GPR32:$mask),
    "store_v_mask $srcDest, $mask, $addr",
    [(int_nyuzi_block_storei_masked ADDRri:$addr, v16i32:$srcDest, v16i1:$mask)],
    FmtM_BlockMasked,
    0>;

  def INT_SCATTER_STOREI : FormatMUnmaskedInst<
    (outs),
    (ins VR512:$srcDest, MEMV15:$addr),
    "store_scat $srcDest, $addr",
    [(int_nyuzi_scatter_storei VADDRri:$addr, v16i32:$srcDest)],
    FmtM_ScGath,
    0>;

  def INT_SCATTER_STOREI_MASKED : FormatMMaskedInst<
    (outs),
    (ins VR512:$srcDest, MEMV10:$addr, GPR32:$mask),
    "store_scat_mask $srcDest, $mask, $addr",
    [(int_nyuzi_scatter_storei_masked VADDRri:$addr, v16i32:$srcDest, v16i1:$mask)],
    FmtM_ScGathMasked,
    0>;
}

def : Pat<(store f32:$srcDest, ADDRri:$addr), (SW f32:$srcDest, ADDRri:$addr)>;
def : Pat<(store v16f32:$srcDest, ADDRri:$addr), (BLOCK_STOREI v16f32:$srcDest, ADDRri:$addr)>;
def : Pat<(int_nyuzi_block_storef_masked ADDRri:$addr, v16f32:$srcDest, v16i1:$mask),
  (INT_BLOCK_STOREI_MASKED v16f32:$srcDest, ADDRri:$addr, v16i1:$mask)>;
def : Pat<(int_nyuzi_scatter_storef VADDRri:$addr, v16f32:$srcDest),
  (INT_SCATTER_STOREI v16f32:$srcDest, VADDRri:$addr)>;
def : Pat<(int_nyuzi_scatter_storef_masked VADDRri:$addr, v16f32:$srcDest, v16i1:$mask),
  (INT_SCATTER_STOREI_MASKED v16f32:$srcDest, VADDRri:$addr, v16i1:$mask)>;
def : Pat<(store v16i1:$srcDest, ADDRri:$addr), (SS v16i1:$srcDest, ADDRri:$addr)>;

// Atomics
let usesCustomInserter = 1 in {
  defm ATOMIC_LOAD_ADD : AtomicBinary<atomic_load_add>;
  defm ATOMIC_LOAD_SUB : AtomicBinary<atomic_load_sub>;
  defm ATOMIC_LOAD_AND : AtomicBinary<atomic_load_and>;
  defm ATOMIC_LOAD_OR  : AtomicBinary<atomic_load_or>;
  defm ATOMIC_LOAD_XOR : AtomicBinary<atomic_load_xor>;
  defm ATOMIC_LOAD_NAND : AtomicBinary<atomic_load_nand>;

  def ATOMIC_CMP_SWAP : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$ptr, GPR32:$cmp, GPR32:$swap),
    [(set i32:$dest, (atomic_cmp_swap GPR32:$ptr, GPR32:$cmp,
      GPR32:$swap))]>;

  def ATOMIC_SWAP : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$ptr, GPR32:$swap),
    [(set i32:$dest, (atomic_swap GPR32:$ptr, GPR32:$swap))]>;
}

//////////////////////////////////////////////////////////////////
// Cache Control
//////////////////////////////////////////////////////////////////

def DFLUSH : FormatCOneOp<
  (outs),
  (ins GPR32:$ptr),
  "dflush $ptr",
  [],
  FmtC_DFlush>;

def DINVALIDATE : FormatCOneOp<
  (outs),
  (ins GPR32:$ptr),
  "dinvalidate $ptr",
  [],
  FmtC_DInvalidate>;

def IINVALIDATE : FormatCOneOp<
  (outs),
  (ins GPR32:$ptr),
  "iinvalidate $ptr",
  [],
  FmtC_IInvalidate>;

def MEMBAR : FormatCInst<
  (outs),
  (ins i32imm:$imm1, i32imm:$imm2),
  "membar",
  [(atomic_fence imm:$imm1, imm:$imm2)],
  FmtC_MemBar>;

def TLBINVAL : FormatCOneOp<
  (outs),
  (ins GPR32:$ptr),
  "tlbinval $ptr",
  [],
  FmtC_TLBInval>;

def TLBINVALALL : FormatCInst<
  (outs),
  (ins),
  "tlbinvalall",
  [],
  FmtC_TLBInvalAll>;

def DTLBINSERT : FormatCTwoOp<
  (outs),
  (ins GPR32:$ptr, GPR32:$physAddr),
  "dtlbinsert $ptr, $physAddr",
  [],
  FmtC_DTLBInsert>;

def ITLBINSERT : FormatCTwoOp<
  (outs),
  (ins GPR32:$ptr, GPR32:$physAddr),
  "itlbinsert $ptr, $physAddr",
  [],
  FmtC_ITLBInsert>;

//////////////////////////////////////////////////////////////////
// Branch
//////////////////////////////////////////////////////////////////

let isTerminator = 1 in {
  def B : NonRegisterBranchInst<
    (outs),
    (ins brtarget25:$dest),
    "b $dest",
    [(br bb:$dest)],
    BT_Uncond> {
    let isBarrier = 1;
  }

  def BREG : RegisterBranchInst<
    (outs),
    (ins GPR32:$reg),
    "b $reg",
    [(brind GPR32:$reg)],
    BT_Reg> {

    let isBarrier = 1;
    let isIndirectBranch = 1;
    let dest = 0;
  }

  def BZ : RegisterBranchInst<
    (outs),
    (ins GPR32:$reg, brtarget20:$dest),
    "bz $reg, $dest",
    [],
    BT_IfZero>;

  def BNZ : RegisterBranchInst<
    (outs),
    (ins GPR32:$reg, brtarget20:$dest),
    "bnz $reg, $dest",
    [],
    BT_IfNotZero>;
}

// Branch patterns
def : Pat<(brcond (i32 (setne i32:$lhs, 0)), bb:$dest), (BNZ i32:$lhs, bb:$dest)>;
def : Pat<(brcond (i32 (seteq i32:$lhs, 0)), bb:$dest), (BZ i32:$lhs, bb:$dest)>;
def : Pat<(brcond i32:$lhs, bb:$dest), (BNZ i32:$lhs, bb:$dest)>;

def RET : RegisterBranchInst<
  (outs),
  (ins),
  "ret",
  [(return)],
  BT_Reg> {
  let reg = 31; // return address
  let dest = 0;
  let Uses = [ RA_REG ];
  let isReturn = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}

// Return from exception
def ERET : RegisterBranchInst<
  (outs),
  (ins),
  "eret",
  [],
  BT_Eret> {
  let reg = 0;
  let dest = 0;
  let isReturn = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}


// These pseudo ops capture outgoing argument space on the stack and will be removed
// by later passes.
let Defs = [ SP_REG ], Uses = [ SP_REG ], hasSideEffects = 1 in {
  def ADJCALLSTACKDOWN : Pseudo<
    (outs),
    (ins i32imm:$amt1, i32imm:$amt2),
    [(callseq_start timm:$amt1, timm:$amt2)]>;

  def ADJCALLSTACKUP : Pseudo<
    (outs),
    (ins i32imm:$amt1, i32imm:$amt2),
    [(callseq_end timm:$amt1, timm:$amt2)]>;
}

// Note: Unlike other branches, call is not a terminator: it does not end a
// basic block (subtle and serious bugs occur if it is marked as such).
let isCall = 1, Defs = [ RA_REG ] in {
  def CALLSYM : NonRegisterBranchInst<
    (outs),
    (ins calltarget:$dest, variable_ops),
    "call $dest",
    [],
    BT_Call>;

  def CALLREG : RegisterBranchInst<
    (outs),
    (ins GPR32:$reg, variable_ops),
    "call $reg",
    [(call i32:$reg)],
    BT_CallReg> {
  }
}

def : Pat<(call tglobaladdr:$dest),
          (CALLSYM tglobaladdr:$dest)>;
def : Pat<(call texternalsym:$dest),
          (CALLSYM texternalsym:$dest)>;

//
// SELECT pseudo instructions. This architecture doesn't actually have a scalar
// conditional move instruction. These will be replaced in a later pass
// with a diamond pattern of conditional branches.
//
let usesCustomInserter = 1 in {
  def SELECTI : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$pred, GPR32:$true, GPR32:$false),
    [(set i32:$dest, (selcondresult i32:$pred, i32:$true, i32:$false))]>;

  def SELECTF : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$pred, GPR32:$true, GPR32:$false),
    [(set f32:$dest, (selcondresult i32:$pred, f32:$true, f32:$false))]>;

  def SELECTMASK : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$pred, GPR32:$true, GPR32:$false),
    [(set v16i1:$dest, (selcondresult i32:$pred, v16i1:$true, v16i1:$false))]>;

  def SELECTVI : Pseudo<
    (outs VR512:$dest),
    (ins GPR32:$pred, VR512:$true, VR512:$false),
    [(set v16i32:$dest, (selcondresult i32:$pred, v16i32:$true, v16i32:$false))]>;

  def SELECTVF : Pseudo<
    (outs VR512:$dest),
    (ins GPR32:$pred, VR512:$true, VR512:$false),
    [(set v16f32:$dest, (selcondresult i32:$pred, v16f32:$true, v16f32:$false))]>;
}

//////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////

def SYSCALL : NyuziInstruction<
  (outs),
  (ins SIMM14OP:$index),
  "syscall $index",
  [],
  II_INT> {
  // immediate, format 0
  bits<14> index;
  let Inst{23-10} = index;
  let Inst{27-24} = 2;  // opcode
}

def BREAK : NyuziInstruction<
  (outs),
  (ins),
  "break",
  [(trap)],
  II_INT> {
  let Inst{31-29} = 0b110;
  let Inst{25-20} = 0x3e;   // opcode
}

def READ_CONTROL_REG : FormatMInst<
  (outs GPR32:$dest),
  (ins i32imm:$cr),
  "getcr $dest, $cr",
  [(set i32:$dest, (int_nyuzi_read_control_reg imm:$cr))],
  FmtM_ControlReg,
  1> {
  bits <5> cr;
  bits <5> dest;

  let Inst{4-0} = cr;
  let Inst{9-5} = dest;
}

def WRITE_CONTROL_REG : FormatMInst<
  (outs),
  (ins i32imm:$cr, GPR32:$src),
  "setcr $src, $cr",
  [(int_nyuzi_write_control_reg imm:$cr, i32:$src)],
  FmtM_ControlReg,
  0> {
  bits <5> cr;
  bits <5> src;

  let Inst{4-0} = cr;
  let Inst{9-5} = src;
}

// This instruction is matched by forms like FrameIndex
// Note this takes MEMS14 operand (vs. the MEMS15 format a normal memory
// instruction would) because it is an format instruction and has a smaller
// immediate field.
def LEA_MEM : NyuziInstruction<
  (outs GPR32:$dest),
  (ins MEMS14:$addr),
  "lea $dest, $addr",
  [(set i32:$dest, ADDRri:$addr)],
  II_INT> {

  bits<20> addr;
  bits<5> dest;

  let Inst{30-29} = FmtI_S.Value;
  let Inst{28-24} = 5;  // Add
  let Inst{23-10} = addr{18-5};  // Grab the offset part of address
  let Inst{9-5} = dest;
  let Inst{4-0} = addr{4-0};    // base register
}

def LEA_SYM : NyuziInstruction<
  (outs GPR32:$dest),
  (ins symref:$label),
  "lea $dest, $label",
  [],
  II_INT> {
  let isPseudo = 1;
}


def NOP : NyuziInstruction<
  (outs),
  (ins),
  "nop",
  [],
  II_INT>;

// Conversions
def : Pat<(v16f32 (bitconvert (v16i32 VR512:$src))), (v16f32 VR512:$src)>;
def : Pat<(v16i32 (bitconvert (v16f32 VR512:$src))), (v16i32 VR512:$src)>;
def : Pat<(f32 (bitconvert (i32 GPR32:$src))), (f32 GPR32:$src)>;
def : Pat<(i32 (bitconvert (f32 GPR32:$src))), (i32 GPR32:$src)>;

//
// Constants
//
def HI19 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((uint64_t)N->getZExtValue() >> 13, SDLoc(N),
                                   MVT::i32);
}]>;

def LO13 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((uint64_t)N->getZExtValue() & 0x1fff,
                                   SDLoc(N), MVT::i32);
}]>;

// Checks if the immediate can be created using only movehi (low bits are 0)
def imm_hi  : PatLeaf<(imm), [{ return (N->getZExtValue() & 0x1fff) == 0; }]>;

// Any constants that are not matched in patterns as small immediates will
// get picked up by the following patterns, which synthesize them using the
// movehi instruction.

// If only high bits are set, use movehi only
def : Pat<(i32 imm_hi:$imm), (MOVEHI (HI19 imm:$imm))>;

// If low bits are set use movehi/or combination
def : Pat<(i32 imm:$imm), (ORSSI (MOVEHI (HI19 imm:$imm)), (LO13 imm:$imm))>;

def LI : NyuziInstruction<
  (outs GPR32:$dest),
  (ins i32imm:$imm),
  "li $dest, $imm",
  [],
  II_PSEUDO> {
  let isPseudo = 1;
}

def : Pat<(movehi tconstpool:$dst), (MOVEHI tconstpool:$dst)>;
def : Pat<(orlo i32:$val, tconstpool:$dst), (ORSSI i32:$val, tconstpool:$dst)>;
def : Pat<(movehi tglobaladdr:$dst), (MOVEHI tglobaladdr:$dst)>;
def : Pat<(orlo i32:$val, tglobaladdr:$dst), (ORSSI i32:$val, tglobaladdr:$dst)>;
def : Pat<(movehi tblockaddress:$dst), (MOVEHI tblockaddress:$dst)>;
def : Pat<(orlo i32:$val, tblockaddress:$dst), (ORSSI i32:$val, tblockaddress:$dst)>;

def : Pat<(movehi tjumptable:$dst), (MOVEHI tjumptable:$dst)>;
def : Pat<(orlo i32:$val, tjumptable:$dst), (ORSSI i32:$val, tjumptable:$dst)>;

