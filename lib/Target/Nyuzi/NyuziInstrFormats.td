//===-- NyuziInstrFormats.td - Target Description for Nyuzi Target -----------===//
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

//////////////////////////////////////////////////////////////////
// Node types
//////////////////////////////////////////////////////////////////

def simm9  : PatLeaf<(imm), [{ return isInt<9>(N->getSExtValue()); }]>;
def simm14  : PatLeaf<(imm), [{ return isInt<14>(N->getSExtValue()); }]>;

// A splat is a vector with the same value in all lanes. NyuziTargetLowering
// detects this condition and converts it to a SPLAT node.
// Many instructions for this architecture can mix scalar and vector operands.
// This pattern allows us to detect that case and match it explicitly.
def splat : SDNode<"NyuziISD::SPLAT", SDTypeProfile<1, 1, [SDTCisEltOfVec<1, 0>]>>;
def wrapper : SDNode<"NyuziISD::WRAPPER", SDTIntUnaryOp>;
def reciprocal : SDNode<"NyuziISD::RECIPROCAL_EST", SDTFPUnaryOp>;
def movehi : SDNode<"NyuziISD::MOVEHI", SDTIntUnaryOp>;
def orlo : SDNode<"NyuziISD::ORLO", SDTypeProfile<1, 2, [SDTCisSameAs<0, 1>, SDTCisSameAs<0, 2>]>>;

// Nop conversions between i1 vectors and integers.
// Mapped to pseudo instructions because ISel doesn't like type punning in patterns.
def mask_to_int : SDNode<"NyuziISD::MASK_TO_INT", SDTypeProfile<1, 1,
  [SDTCisVT<0, i32>, SDTCisVT<1, v16i1>]>>;
def mask_from_int : SDNode<"NyuziISD::MASK_FROM_INT", SDTypeProfile<1, 1,
  [SDTCisVT<0, v16i1>, SDTCisVT<1, i32>]>>;

def return : SDNode<"NyuziISD::RET_FLAG",
  SDTypeProfile<0, 0, []>,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// selcondresult is (dest, predicate, trueval, falseval)
def selcondresult : SDNode<"NyuziISD::SEL_COND_RESULT", SDTypeProfile<1, 3, [
  SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>]>>;

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;
def VADDRri : ComplexPattern<v16i32, 2, "SelectADDRri", [], []>;

def MemAsmOperandS10 : AsmOperandClass {
  let Name = "MemS10";
  let ParserMethod = "ParseMemoryOperandS10";
}

def MemAsmOperandS14 : AsmOperandClass {
  let Name = "MemS14";
  let ParserMethod = "ParseMemoryOperandS14";
}

def MemAsmOperandS15 : AsmOperandClass {
  let Name = "MemS15";
  let ParserMethod = "ParseMemoryOperandS15";
}

def MemAsmOperandV10 : AsmOperandClass {
  let Name = "MemV10";
  let ParserMethod = "ParseMemoryOperandV10";
}

def MemAsmOperandV15 : AsmOperandClass {
  let Name = "MemV15";
  let ParserMethod = "ParseMemoryOperandV15";
}

class MEMS : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let EncoderMethod = "encodeMemoryOpValue";
}

def MEMS10 : MEMS {
  let ParserMatchClass = MemAsmOperandS10;
  let MIOperandInfo = (ops GPR32, i32imm);
  let DecoderMethod = "decodeScalarMemoryOpValue";
}

def MEMS14 : MEMS {
  let ParserMatchClass = MemAsmOperandS14;
  let MIOperandInfo = (ops GPR32, i32imm);
  let DecoderMethod = "decodeScalarMemoryOpValue";
}

def MEMS15 : MEMS {
  let ParserMatchClass = MemAsmOperandS15;
  let MIOperandInfo = (ops GPR32, i32imm);
  let DecoderMethod = "decodeScalarMemoryOpValue";
}

class MEMV : Operand<v16i32> {
  let PrintMethod = "printMemOperand";
  let EncoderMethod = "encodeMemoryOpValue";
}

def MEMV10 : MEMV {
  let ParserMatchClass = MemAsmOperandV10;
  let MIOperandInfo = (ops VR512, i32imm);
  let DecoderMethod = "decodeVectorMemoryOpValue";
}

def MEMV15 : MEMV {
  let ParserMatchClass = MemAsmOperandV15;
  let MIOperandInfo = (ops VR512, i32imm);
  let DecoderMethod = "decodeVectorMemoryOpValue";
}

def cpooladdr : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let EncoderMethod = "encodeMemoryOpValue";
}

def brtarget20 : Operand<OtherVT> {
  let EncoderMethod = "encodeBranchTargetOpValue20";
  let DecoderMethod = "decodeBranchTargetOpValue20";
}

def brtarget25 : Operand<OtherVT> {
  let EncoderMethod = "encodeBranchTargetOpValue25";
  let DecoderMethod = "decodeBranchTargetOpValue25";
}

def calltarget : Operand<iPTR> {
  let EncoderMethod = "encodeBranchTargetOpValue25";
  let DecoderMethod = "decodeBranchTargetOpValue25";
}

def symref : Operand<OtherVT> {}

def SImmOperand9 : AsmOperandClass  {
  let Name = "SImm9";
  let ParserMethod = "ParseSImm9Value";
}

def SImmOperand14 : AsmOperandClass {
  let Name = "SImm14";
  let ParserMethod = "ParseSImm14Value";
}

def SImmOperand19 : AsmOperandClass {
  let Name = "SImm19";
  let ParserMethod = "ParseSImm19Value";
}

def SIMM9OP : Operand<i32> {
  let DecoderMethod = "decodeSimm9Value";
  let ParserMatchClass = SImmOperand9;
}

def SIMM14OP : Operand<i32> {
  let DecoderMethod = "decodeSimm14Value";
  let ParserMatchClass = SImmOperand14;
}

def SIMM19OP : Operand<i32> {
  let DecoderMethod = "decodeSimm19Value";
  let ParserMatchClass = SImmOperand19;
}

def SDT_NyuziCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def SDT_NyuziCallSeqEnd : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_NyuziCallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end : SDNode<"ISD::CALLSEQ_END", SDT_NyuziCallSeqEnd,
                           [SDNPHasChain, SDNPSideEffect,
                            SDNPOptInGlue, SDNPOutGlue]>;
def SDT_SPCall : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;
def call       : SDNode<"NyuziISD::CALL", SDT_SPCall,
                        [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                        SDNPVariadic]>;

//////////////////////////////////////////////////////////////////
// Instruction Classes
//////////////////////////////////////////////////////////////////

class NyuziInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern, InstrItinClass itin>
  : Instruction {
  let Namespace = "Nyuzi";
  dag OutOperandList = outputs;
  dag InOperandList = inputs;
  let AsmString = asmString;
  let Pattern = pattern;
  let Size = 4;
  let Itinerary = itin;

  field bits<32> Inst;
  field bits<32> SoftFail = 0;  // needed for disassembler
}

class Pseudo<dag outputs, dag inputs, list<dag> pattern>
  : NyuziInstruction<outputs, inputs, "Pseudo", pattern, II_PSEUDO> {
  let isCodeGenOnly = 1;
  let isPseudo = 1;
  let Inst{31-0} = 0;
}

multiclass AtomicBinary<SDNode OpNode> {
  def R : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$ptr, GPR32:$amt),
    [(set i32:$dest, (OpNode GPR32:$ptr, GPR32:$amt))]>;

  def I : Pseudo<
    (outs GPR32:$dest),
    (ins GPR32:$ptr, SIMM14OP:$amt),
    [(set i32:$dest, (OpNode GPR32:$ptr, simm14:$amt))]>;
}

//////////////////////////////////////////////////////////////////
// Format R: Register arithmetic
//////////////////////////////////////////////////////////////////

class FmtR<bits<3> val> {
  bits<3> Value = val;
}

def FmtR_SSS : FmtR<0>;
def FmtR_VVS : FmtR<1>;
def FmtR_VVSM : FmtR<2>;
def FmtR_VVV : FmtR<4>;
def FmtR_VVVM : FmtR<5>;

class FormatRInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<6> opcode, FmtR fmt, InstrItinClass itin>
  : NyuziInstruction<outputs, inputs, asmString, pattern, itin> {
  bits <5> dest;
  bits <5> src2;

  let Inst{31-29} = 0b110;
  let Inst{28-26} = fmt.Value;
  let Inst{25-20} = opcode;
  let Inst{19-15} = src2;
  let Inst{9-5} = dest;
}

class FormatRUnmaskedOneOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<6> opcode, FmtR fmt, InstrItinClass itin>
  : FormatRInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  let Inst{4-0} = 0;
}

class FormatRMaskedOneOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<6> opcode, FmtR fmt, InstrItinClass itin>
  : FormatRInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  bits <5> mask;
  let Inst{14-10} = mask;
  let Inst{4-0} = 0;
}

class FormatRUnmaskedTwoOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<6> opcode, FmtR fmt, InstrItinClass itin>
  : FormatRInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  bits <5> src1;
  let Inst{4-0} = src1;
}

class FormatRMaskedTwoOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<6> opcode, FmtR fmt, InstrItinClass itin>
  : FormatRInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  bits <5> src1;
  bits <5> mask;
  let Inst{14-10} = mask;
  let Inst{4-0} = src1;
}

//////////////////////////////////////////////////////////////////
// Format I: Immediate Arithmetic
//////////////////////////////////////////////////////////////////

class FmtI<bits<2> val> {
  bits<2> Value = val;
}

def FmtI_S : FmtI<0>;
def FmtI_V : FmtI<1>;
def FmtI_EXT : FmtI<2>;
def FmtI_VM : FmtI<3>;

class FormatIInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<5> opcode, FmtI fmt, InstrItinClass itin>
  : NyuziInstruction<outputs, inputs, asmString, pattern, itin> {
  bits <5> dest;
  bits <5> src1;

  let Inst{31} = 0;
  let Inst{30-29} = fmt.Value;
  let Inst{28-24} = opcode;
  let Inst{9-5} = dest;
  let Inst{4-0} = src1;
}

class FormatIMaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<5> opcode, FmtI fmt, InstrItinClass itin>
  : FormatIInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  bits <5> mask;
  bits <9> imm;
  let Inst{23-15} = imm;
  let Inst{14-10} = mask;
}

class FormatIUnmaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  bits<5> opcode, FmtI fmt, InstrItinClass itin>
  : FormatIInst<outputs, inputs, asmString, pattern, opcode, fmt, itin> {
  bits <14> imm;
  let Inst{23-10} = imm;
}

multiclass TwoOpIntArith<string operator, SDNode OpNode, bits<6> opcode> {
  // Format R
  // Scalar = Scalar Op Scalar
  def SSS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set i32:$dest, (OpNode i32:$src1, i32:$src2))],
    opcode,
    FmtR_SSS,
    II_INT>;

  // Vector = Vector Op Vector
  def VVV : FormatRUnmaskedTwoOpInst<
    (outs VR512:$dest),
    (ins VR512:$src1, VR512:$src2),
    operator # " $dest, $src1, $src2",
    [(set v16i32:$dest, (OpNode v16i32:$src1, v16i32:$src2))],
    opcode,
    FmtR_VVV,
    II_INT>;

  // Vector = Vector Op Scalar
  def VVS : FormatRUnmaskedTwoOpInst<
    (outs VR512:$dest),
    (ins VR512:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set v16i32:$dest, (OpNode v16i32:$src1, (splat i32:$src2)))],
    opcode,
    FmtR_VVS,
    II_INT>;

  let Constraints = "$dest = $oldvalue" in {
    // Vector = Vector op Vector, masked
    def VVVM : FormatRMaskedTwoOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src1, VR512:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src1, $src2",
      [(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, v16i32:$src2), v16i32:$oldvalue))],
      opcode,
      FmtR_VVVM,
      II_INT>;

    // Vector = Vector Op Scalar, masked
    def VVSM : FormatRMaskedTwoOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src1, GPR32:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src1, $src2",
      [(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat i32:$src2)), v16i32:$oldvalue))],
      opcode,
      FmtR_VVSM,
      II_INT>;
  }

  // Format I
  // Scalar = Scalar Op Immediate
  def SSI : FormatIUnmaskedInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, SIMM14OP:$imm),
    operator # " $dest, $src1, $imm",
    [(set i32:$dest, (OpNode i32:$src1, (i32 simm14:$imm)))],
    opcode{4-0},
    FmtI_S,
    II_INT>;

  // Vector = Vector Op Immediate
  def VVI : FormatIUnmaskedInst<
    (outs VR512:$dest),
    (ins VR512:$src1, SIMM14OP:$imm),
    operator # " $dest, $src1, $imm",
    [(set v16i32:$dest, (OpNode v16i32:$src1, (splat simm14:$imm)))],
    opcode{4-0},
    FmtI_V,
    II_INT>;

  let Constraints = "$dest = $oldvalue" in {
    // Vector = Vector Op Immediate, masked
    def VVIM : FormatIMaskedInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src1, SIMM9OP:$imm, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src1, $imm",
      [(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat simm9:$imm)), v16i32:$oldvalue))],
      opcode{4-0},
      FmtI_VM,
      II_INT>;
  }
}

multiclass TwoOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> {
  // Scalar = Scalar Op Scalar
  def SSS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set GPR32:$dest, (OpNode f32:$src1, f32:$src2))],
    opcode,
    FmtR_SSS,
    II_FLOAT>;

  // Vector = Vector Op Vector
  def VVV : FormatRUnmaskedTwoOpInst<
    (outs VR512:$dest),
    (ins VR512:$src1, VR512:$src2),
    operator # " $dest, $src1, $src2",
    [(set VR512:$dest, (OpNode v16f32:$src1, v16f32:$src2))],
    opcode,
    FmtR_VVV,
    II_FLOAT>;

  // Vector = Vector Op Scalar
  def VVS : FormatRUnmaskedTwoOpInst<
    (outs VR512:$dest),
    (ins VR512:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set VR512:$dest, (OpNode v16f32:$src1, (splat f32:$src2)))],
    opcode,
    FmtR_VVS,
    II_FLOAT>;

  // Predicated
  let Constraints = "$dest = $oldvalue" in {
    // Vector = Vector Op Vector, masked
    def VVVM : FormatRMaskedTwoOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src1, VR512:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src1, $src2",
      [(set VR512:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1,
        v16f32:$src2), v16f32:$oldvalue))],
      opcode,
      FmtR_VVVM,
      II_FLOAT>;

    // Vector = Vector Op Scalar, masked
    def VVSM : FormatRMaskedTwoOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src1, GPR32:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src1, $src2",
      [(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1,
        (splat f32:$src2)), v16f32:$oldvalue))],
      opcode,
      FmtR_VVSM,
      II_FLOAT>;
  }
}

multiclass OneOpIntArith<string operator, SDNode OpNode, bits<6> opcode> {
  def SS : FormatRUnmaskedOneOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src2),
    operator # " $dest, $src2",
    [(set i32:$dest, (OpNode i32:$src2))],
    opcode,
    FmtR_SSS,
    II_INT>;

  def VS : FormatRUnmaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$src2),
    operator # " $dest, $src2",
    [(set v16i32:$dest, (OpNode (splat i32:$src2)))],
    opcode,
    FmtR_VVS,
    II_INT>;

  def VV : FormatRUnmaskedOneOpInst<
    (outs VR512:$dest),
    (ins VR512:$src2),
    operator # " $dest, $src2",
    [(set v16i32:$dest, (OpNode v16i32:$src2))],
    opcode,
    FmtR_VVV,
    II_INT>;

  // Predicated
  let Constraints = "$dest = $oldvalue" in {
    def VVM : FormatRMaskedOneOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src2",
      [(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src2),
        v16i32:$oldvalue))],
      opcode,
      FmtR_VVVM,
      II_INT>;

    def VSM : FormatRMaskedOneOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src2",
      [(set v16i32:$dest, (vselect v16i1:$mask, (OpNode (splat i32:$src2)),
        v16i32:$oldvalue))],
      opcode,
      FmtR_VVSM,
      II_INT>;
  }
}

multiclass OneOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> {
  def SS : FormatRUnmaskedOneOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src2),
    operator # " $dest, $src2",
    [(set f32:$dest, (OpNode f32:$src2))],
    opcode,
    FmtR_SSS,
    II_FLOAT>;

  def VS : FormatRUnmaskedOneOpInst<
    (outs VR512:$dest),
    (ins GPR32:$src2),
    operator # " $dest, $src2",
    [(set v16f32:$dest, (OpNode (splat f32:$src2)))],
    opcode,
    FmtR_VVS,
    II_FLOAT>;

  def VV : FormatRUnmaskedOneOpInst<
    (outs VR512:$dest),
    (ins VR512:$src2),
    operator # " $dest, $src2",
    [(set v16f32:$dest, (OpNode v16f32:$src2))],
    opcode,
    FmtR_VVV,
    II_FLOAT>;

  // Predicated
  let Constraints = "$dest = $oldvalue" in {
    def VVM : FormatRMaskedOneOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src2",
      [(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src2),
        v16f32:$oldvalue))],
      opcode,
      FmtR_VVVM,
      II_FLOAT>;

    def VSM : FormatRMaskedOneOpInst<
      (outs VR512:$dest),
      (ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
      operator # "_mask $dest, $mask, $src2",
      [(set v16f32:$dest, (vselect v16i1:$mask, (OpNode (splat f32:$src2)),
        v16f32:$oldvalue))],
      opcode,
      FmtR_VVSM,
      II_FLOAT>;
  }
}

multiclass IntCompareInst<string operator, CondCode condition,
  bits<6> opcode> {
  // Register
  def SS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set i32:$dest, (setcc i32:$src1, i32:$src2, condition))],
    opcode,
    FmtR_SSS,
    II_INT>;

  def VV : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins VR512:$src1, VR512:$src2),
    operator # " $dest, $src1, $src2",
    [(set v16i1:$dest, (setcc v16i32:$src1, v16i32:$src2, condition))],
    opcode,
    FmtR_VVV,
    II_INT>;

  def VS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins VR512:$src1, GPR32:$src2),
    operator # " $dest, $src1, $src2",
    [(set v16i1:$dest, (setcc v16i32:$src1, (splat i32:$src2), condition))],
    opcode,
    FmtR_VVS,
    II_INT>;

  // Immediate
  def SI : FormatIUnmaskedInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, SIMM14OP:$imm),
    operator # " $dest, $src1, $imm",
    [(set i32:$dest, (setcc i32:$src1, simm14:$imm, condition))],
    opcode{4-0},
    FmtI_S,
    II_INT>;

  def VI : FormatIUnmaskedInst<
    (outs GPR32:$dest),
    (ins VR512:$src1, SIMM14OP:$imm),
    operator # " $dest, $src1, $imm",
    [(set v16i1:$dest, (setcc v16i32:$src1, (splat simm14:$imm), condition))],
    opcode{4-0},
    FmtI_V,
    II_INT>;
}

multiclass FloatCompareInst<string operator, SDNode OpNode, bits<6> opcode> {
  def SS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins GPR32:$src1, GPR32:$src2),
    operator # "_f $dest, $src1, $src2",
    [(set i32:$dest, (OpNode f32:$src1, f32:$src2))],
    opcode,
    FmtR_SSS,
    II_FLOAT>;

  def VV : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins VR512:$src1, VR512:$src2),
    operator # "_f $dest, $src1, $src2",
    [(set v16i1:$dest, (OpNode v16f32:$src1, v16f32:$src2))],
    opcode,
    FmtR_VVV,
    II_FLOAT>;

  def VS : FormatRUnmaskedTwoOpInst<
    (outs GPR32:$dest),
    (ins VR512:$src1, GPR32:$src2),
    operator # "_f $dest, $src1, $src2",
    [(set v16i1:$dest, (OpNode v16f32:$src1, (splat f32:$src2)))],
    opcode,
    FmtR_VVS,
    II_FLOAT>;
}


//////////////////////////////////////////////////////////////////
// Format M: Memory instructions
//////////////////////////////////////////////////////////////////

class FmtM<bits<4> val> {
  bits<4> Value = val;
}

def FmtM_Byte_Unsigned : FmtM<0>;
def FmtM_Byte_Signed : FmtM<1>;
def FmtM_Short_Unsigned : FmtM<2>;
def FmtM_Short_Signed : FmtM<3>;
def FmtM_Word : FmtM<4>;
def FmtM_Sync : FmtM<5>;
def FmtM_ControlReg : FmtM<6>;
def FmtM_Block : FmtM<7>;
def FmtM_BlockMasked : FmtM<8>;
def FmtM_ScGath : FmtM<13>;
def FmtM_ScGathMasked : FmtM<14>;

class FormatMInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtM fmt, bits <1> isLoad>
  : NyuziInstruction<outputs, inputs, asmString, pattern, II_MEMORY> {
  bits <5> srcDest;

  let Inst{31} = 1;
  let Inst{29} = isLoad;
  let Inst{28-25} = fmt.Value;
  let Inst{9-5} = srcDest;
  let hasSideEffects = 1;
}

class FormatMMaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtM fmt, bits <1> isLoad>
  : FormatMInst<outputs, inputs, asmString, pattern, fmt, isLoad> {
  bits <20> addr;  // Is offset/ptr, this is set up by encodeMemoryOpValue.
  bits <5> mask;

  let Inst{24-15} = addr{14-5};
  let Inst{14-10} = mask;
  let Inst{4-0} = addr{4-0};
}

class FormatMUnmaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtM fmt, bits <1> isLoad>
  : FormatMInst<outputs, inputs, asmString, pattern, fmt, isLoad> {
  bits <20> addr;  // Is offset/ptr, this is set up by encodeMemoryOpValue.

  let Inst{24-10} = addr{19-5};
  let Inst{4-0} = addr{4-0};
}

class ScalarLoadInst<string suffix, PatFrag op, FmtM fmt>
  : FormatMUnmaskedInst<
    (outs GPR32:$srcDest),
    (ins MEMS15:$addr),
    "load_" # suffix # " $srcDest, $addr",
    [(set i32:$srcDest, (i32 (op ADDRri:$addr)))],
    fmt,
    1>;

class ScalarStoreInst<string suffix, PatFrag op, FmtM fmt>
  : FormatMUnmaskedInst<
      (outs),
      (ins GPR32:$srcDest, MEMS15:$addr),
      "store_" # suffix # " $srcDest, $addr",
      [(op i32:$srcDest, ADDRri:$addr)],
      fmt,
      0> {
}


//////////////////////////////////////////////////////////////////
// Format C (cache control)
//////////////////////////////////////////////////////////////////

class FmtC<bits<3> val> {
  bits<3> Value = val;
}

def FmtC_DTLBInsert : FmtC<0>;
def FmtC_DInvalidate : FmtC<1>;
def FmtC_DFlush : FmtC<2>;
def FmtC_IInvalidate : FmtC<3>;
def FmtC_MemBar : FmtC<4>;
def FmtC_TLBInval : FmtC<5>;
def FmtC_TLBInvalAll : FmtC<6>;
def FmtC_ITLBInsert : FmtC<7>;

class FormatCInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtC fmt>
  : NyuziInstruction<outputs, inputs, asmString, pattern, II_MEMORY> {
  let Inst{31-28} = 0b1110;
  let Inst{27-25} = fmt.Value;
}

// XXX Haven't implemented adding an offset
class FormatCOneOp<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtC fmt>
  : FormatCInst<outputs, inputs, asmString, pattern, fmt> {
  bits<5> ptr;

  let Inst{4-0} = ptr;
}

class FormatCTwoOp<dag outputs, dag inputs, string asmString, list<dag> pattern,
  FmtC fmt>
  : FormatCOneOp<outputs, inputs, asmString, pattern, fmt> {
  bits<5> physAddr;

  let Inst{9-5} = physAddr;
}

//////////////////////////////////////////////////////////////////
// Format B: Branch Instruction
//////////////////////////////////////////////////////////////////

class BranchType<bits<3> val> {
  bits<3> Value = val;
}

def BT_Reg : BranchType<0>;
def BT_IfZero : BranchType<1>;
def BT_IfNotZero : BranchType<2>;
def BT_Uncond : BranchType<3>;
def BT_Call : BranchType<4>;
def BT_CallReg : BranchType<6>;
def BT_Eret : BranchType<7>;

class BranchInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  BranchType type>
  : NyuziInstruction<outputs, inputs, asmString, pattern, II_BRANCH> {
  let isBranch = 1;
  let Inst{31-28} = 0b1111;
  let Inst{27-25} = type.Value;
}

class RegisterBranchInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
  BranchType type>
  : BranchInst<outputs, inputs, asmString, pattern, type> {

  bits<5> reg;
  bits<20> dest;

  let Inst{24-5} = dest;
  let Inst{4-0} = reg;
}

class NonRegisterBranchInst<dag outputs, dag inputs, string asmString,
  list<dag> pattern, BranchType type>
  : BranchInst<outputs, inputs, asmString, pattern, type>
{
  bits<25> dest;
  let Inst{24-0} = dest;
}
