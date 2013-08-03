//===-- VectorProcInstrFormats.td - Target Description for VectorProc Target -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the VectorProc instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

//////////////////////////////////////////////////////////////////
// Node types
//////////////////////////////////////////////////////////////////

def simm13  : PatLeaf<(imm), [{ return isInt<13>(N->getSExtValue()); }]>;
def simm8  : PatLeaf<(imm), [{ return isInt<8>(N->getSExtValue()); }]>;

// A splat is a vector with the same value in all lanes. VectorProcTargetLowering 
// detects this condition and converts it to a SPLAT node.
// Many instructions for this architecture can mix scalar and vector operands.  
// This pattern allows us to detect that case and match it explicitly. 
def splat : SDNode<"VectorProcISD::SPLAT", SDTypeProfile<1, 1, [SDTCisEltOfVec<1, 0>]>>;

def wrapper : SDNode<"VectorProcISD::WRAPPER", SDTIntUnaryOp>;

def reciprocal : SDNode<"VectorProcISD::RECIPROCAL_EST", SDTFPUnaryOp>;

def LoadLiteral : SDNode<"VectorProcISD::LOAD_LITERAL", SDTIntUnaryOp>;

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;

def MEMri : Operand<iPTR> {
	let PrintMethod = "printMemOperand";
	let EncoderMethod = "getMemoryOpValue";
	let MIOperandInfo = (ops ScalarReg, i32imm);
}

def cpooladdr : Operand<iPTR> {
	let PrintMethod = "printMemOperand";
	let EncoderMethod = "getMemoryOpValue";
}

def brtarget : Operand<OtherVT> 
{
	let EncoderMethod = "getJumpTargetOpValue";
}

def calltarget : Operand<iPTR>
{
	let EncoderMethod = "getJumpTargetOpValue";
}

def SDT_SPCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_SPCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>, SDTCisVT<1, i32> ]>;
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SPCallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_SPCallSeqEnd,
                           [SDNPHasChain, SDNPSideEffect, SDNPOptInGlue, SDNPOutGlue]>;
def SDT_SPCall : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;
def call       : SDNode<"VectorProcISD::CALL", SDT_SPCall,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                            SDNPVariadic]>;

//////////////////////////////////////////////////////////////////
// Instruction Classes
//////////////////////////////////////////////////////////////////

class VPInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: Instruction 
{
	let Namespace = "VectorProc";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let AsmString = asmString;
	let Pattern = pattern;
	let Size = 4;

	field bits<32> Inst;
}

class Pseudo<dag outputs, dag inputs, list<dag> pattern>
	: VPInstruction<outputs, inputs, "Pseudo", pattern>
{
	let Namespace = "VectorProc";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let Pattern = pattern;
	let isCodeGenOnly = 1;
	let isPseudo = 1;
	let Inst{31-0} = 0;
}


//////////////////////////////////////////////////////////////////
// Format A: Register arithmetic
//////////////////////////////////////////////////////////////////

class AFmt<bits<3> val> {
	bits<3> Value = val;
}

def FmtA_SSS : AFmt<0>;
def FmtA_VVS : AFmt<1>;
def FmtA_VVSM : AFmt<2>;
def FmtA_VVV : AFmt<4>;
def FmtA_VVVM : AFmt<5>;

class FormatAInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<6> opcode, AFmt fmt> 
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	bits <5> dest;

	let Inst{31-29} = 6;
	let Inst{28-26} = fmt.Value;
	let Inst{25-20} = opcode;
	let Inst{9-5} = dest;
}

class FormatAUnmaskedOneOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<6> opcode, AFmt fmt> 
	: FormatAInst<outputs, inputs, asmString, pattern, opcode, fmt>
{
	bits <5> src2;
	let Inst{19-15} = src2;
	let Inst{4-0} = 0;
}

class FormatAMaskedOneOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<6> opcode, AFmt fmt> 
	: FormatAInst<outputs, inputs, asmString, pattern, opcode, fmt>
{
	bits <5> src2;
	bits <5> mask;
	let Inst{19-15} = src2;
	let Inst{14-10} = mask;
	let Inst{4-0} = 0;
}

class FormatAUnmaskedTwoOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<6> opcode, AFmt fmt> 
	: FormatAInst<outputs, inputs, asmString, pattern, opcode, fmt>
{
	bits <5> src1;
	bits <5> src2;
	let Inst{19-15} = src2;
	let Inst{4-0} = src1;
}

class FormatAMaskedTwoOpInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<6> opcode, AFmt fmt> 
	: FormatAInst<outputs, inputs, asmString, pattern, opcode, fmt>
{
	bits <5> src1;
	bits <5> src2;
	bits <5> mask;
	let Inst{19-15} = src2;
	let Inst{14-10} = mask;
	let Inst{4-0} = src1;
}

//////////////////////////////////////////////////////////////////
// Format B: Register/Immediate Arithmetic
//////////////////////////////////////////////////////////////////

class BFmt<bits<3> val> {
	bits<3> Value = val;
}

def FmtB_SS : BFmt<0>;
def FmtB_VV : BFmt<1>;
def FmtB_VVM : BFmt<2>;
def FmtB_VS : BFmt<4>;
def FmtB_VSM : BFmt<5>;

class FormatBInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<5> opcode, BFmt fmt>  
	: VPInstruction<outputs, inputs, asmString, pattern> 
{
	bits <5> dest;
	bits <5> src1;

	let Inst{31} = 0;
	let Inst{30-28} = fmt.Value;
	let Inst{27-23} = opcode;
	let Inst{9-5} = dest;
	let Inst{4-0} = src1;
}

class FormatBMaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<5> opcode, BFmt fmt> 
	: FormatBInst<outputs, inputs, asmString, pattern, opcode, fmt> 
{
	bits <5> mask;
	bits <8> imm;
	let Inst{22-15} = imm;
	let Inst{14-10} = mask;
}

class FormatBUnmaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	bits<5> opcode, BFmt fmt> 
	: FormatBInst<outputs, inputs, asmString, pattern, opcode, fmt> 
{
	bits <13> imm;
	let Inst{22-10} = imm;
}

multiclass TwoOpIntArith<string operator, SDNode OpNode, bits<6> opcode> {
	// Format A
	// Scalar = Scalar Op Scalar
	def SSS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, ScalarReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set i32:$dest, (OpNode i32:$src1, i32:$src2))],
		opcode,
		FmtA_SSS>;
		
	// Vector = Vector Op Vector
	def VVV : FormatAUnmaskedTwoOpInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set v16i32:$dest, (OpNode v16i32:$src1, v16i32:$src2))],
		opcode,
		FmtA_VVV>;

	// Vector = Vector Op Scalar
	def VVS : FormatAUnmaskedTwoOpInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set v16i32:$dest, (OpNode v16i32:$src1, (splat i32:$src2)))],
		opcode,
		FmtA_VVS>;

	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector op Vector, masked
		def VVVM : FormatAMaskedTwoOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, v16i32:$src2), v16i32:$oldvalue))],
			opcode,
			FmtA_VVVM>;

		// Vector = Vector Op Scalar, masked
		def VVSM : FormatAMaskedTwoOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat i32:$src2)), v16i32:$oldvalue))],
			opcode,
			FmtA_VVSM>;
	}

	// Format B
	// Scalar = Scalar Op Immediate
	def SSI : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, i32imm:$imm),
		operator # " $dest, $src1, $imm",
		[(set i32:$dest, (OpNode i32:$src1, (i32 simm13:$imm)))],
		opcode{4-0},
		FmtB_SS>;
	
	// Vector = Vector Op Immediate
	def VVI : FormatBUnmaskedInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1, i32imm:$imm),
		operator # " $dest, $src1, $imm",
		[(set v16i32:$dest, (OpNode v16i32:$src1, (splat simm13:$imm)))],
		opcode{4-0},
		FmtB_VV>;

	// Vector = Scalar Op Immediate
	def VSI : FormatBUnmaskedInst<
		(outs VectorReg:$dest), 
		(ins ScalarReg:$src1, i32imm:$imm),
		operator # " $dest, $src1, $imm",
		[(set v16i32:$dest, (OpNode (splat i32:$src1), (splat simm13:$imm)))],
		opcode{4-0},
		FmtB_VS>;

	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector Op Immediate, masked
		def VVIM : FormatBMaskedInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $imm",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat simm8:$imm)), v16i32:$oldvalue))],
			opcode{4-0},
			FmtB_VVM>;

		// Vector = Scalar Op Immediate, masked
		def VSIM : FormatBMaskedInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, ScalarReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $imm",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode (splat i32:$src1), (splat simm8:$imm)), v16i32:$oldvalue))],
			opcode{4-0},
			FmtB_VSM>;
	}
}

multiclass TwoOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> 
{
	// Scalar = Scalar Op Scalar
	def SSS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, ScalarReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set ScalarReg:$dest, (OpNode f32:$src1, f32:$src2))],
		opcode,
		FmtA_SSS>;

	// Vector = Vector Op Vector
	def VVV : FormatAUnmaskedTwoOpInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set VectorReg:$dest, (OpNode v16f32:$src1, v16f32:$src2))],
		opcode,
		FmtA_VVV>;

	// Vector = Vector Op Scalar
	def VVS : FormatAUnmaskedTwoOpInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # " $dest, $src1, $src2",
		[(set VectorReg:$dest, (OpNode v16f32:$src1, (splat f32:$src2)))],
		opcode,
		FmtA_VVS>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector Op Vector, masked
		def VVVM : FormatAMaskedTwoOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $src2",
			[(set VectorReg:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				v16f32:$src2), v16f32:$oldvalue))],
			opcode,
			FmtA_VVVM>;
		
		// Vector = Vector Op Scalar, masked
		def VVSM : FormatAMaskedTwoOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1, $src2",
			[(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				(splat f32:$src2)), v16f32:$oldvalue))],
			opcode,
			FmtA_VVSM>;
	}
}

multiclass OneOpIntArith<string operator, SDNode OpNode, bits<6> opcode> {
	def SS : FormatAUnmaskedOneOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src2),
		operator # " $dest, $src2",
		[(set i32:$dest, (OpNode i32:$src2))],
		opcode,
		FmtA_SSS>;

	def VS : FormatAUnmaskedOneOpInst<
		(outs VectorReg:$dest), 
		(ins ScalarReg:$src2),
		operator # " $dest, $src2",
		[(set v16i32:$dest, (OpNode (splat i32:$src2)))],
		opcode,
		FmtA_VVS>;

	def VV : FormatAUnmaskedOneOpInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src2),
		operator # " $dest, $src2",
		[(set v16i32:$dest, (OpNode v16i32:$src2))],
		opcode,
		FmtA_VVV>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		def VVM : FormatAMaskedOneOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src2), v16i32:$oldvalue))],
			opcode,
			FmtA_VVVM>;

		def VSM : FormatAMaskedOneOpInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, ScalarReg:$src2, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode (splat i32:$src2)), v16i32:$oldvalue))],
			opcode,
			FmtA_VVSM>;
	}
}

multiclass OneOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> {
	def S : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1),
		operator # " $dest, $src1",
		[(set f32:$dest, (OpNode f32:$src1))],
		opcode,
		FmtA_SSS>;

	def V : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$src1),
		operator # " $dest, $src1",
		[(set v16f32:$dest, (OpNode v16f32:$src1))],
		opcode,
		FmtA_VVV>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		def VM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$oldvalue),
			operator # ".mask $dest, $mask, $src1",
			[(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1), v16f32:$oldvalue))],
			opcode,
			FmtA_VVVM>;
	}
}

multiclass IntCompareInst<string operator, string opsign, CondCode condition, Intrinsic vectorIntrinsic,
	bits<6> opcode> {
	// Instruction format A, integer
	def SSS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, ScalarReg:$src2),
		operator # "." # opsign # " $dest, $src1, $src2",
		[(set i32:$dest, (setcc i32:$src1, i32:$src2, condition))],
		opcode,
		FmtA_SSS>;

	def VVV : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # "." # opsign # " $dest, $src1, $src2",
		[(set v16i1:$dest, (setcc v16i32:$src1, v16i32:$src2, condition))],
		opcode,
		FmtA_VVV>;

	def VVS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # "." # opsign # " $dest, $src1, $src2",
		[(set v16i1:$dest, (setcc v16i32:$src1, (splat i32:$src2), condition))],
		opcode,
		FmtA_VVS>;

	// Instruction format B
	def SSI : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, i32imm:$imm),
		operator # "." # opsign # " $dest, $src1, $imm",
		[(set i32:$dest, (setcc i32:$src1, simm13:$imm, condition))],
		opcode{4-0},
		FmtB_SS>;

	def VVI : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, i32imm:$imm),
		operator # "." # opsign # " $dest, $src1, $imm",
		[(set v16i1:$dest, (setcc v16i32:$src1, (splat simm13:$imm), condition))],
		opcode{4-0},
		FmtB_VV>;

	def VSI : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, i32imm:$imm),
		operator # "." # opsign # " $dest, $src1, $imm",
		[(set i32:$dest, (setcc (splat i32:$src1), (splat simm13:$imm), condition))],
		opcode{4-0},
		FmtB_VS>;

	// Intrinsic forms
	// Ideally, vector comparisons would just use native instructions, but I had a hard 
	// time coercing that into a scalar register, so they are intrinsics for now.

	def VVVint : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # "." # opsign # " $dest, $src1, $src2",
		[(set i32:$dest, (vectorIntrinsic v16i32:$src1, v16i32:$src2))],
		opcode,
		FmtA_VVV>;

	def VVSint : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # "." # opsign # " $dest, $src1, $src2",
		[(set i32:$dest, (vectorIntrinsic v16i32:$src1, (splat i32:$src2)))],
		opcode,
		FmtA_VVS>;

	def VVIint : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$src1, i32imm:$imm),
		operator # "." # opsign # " $dest, $src1, $imm",
		[(set i32:$dest, (vectorIntrinsic v16i32:$src1, (splat simm13:$imm)))],
		opcode{4-0},
		FmtB_VV>;

	def VSIint : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src1, i32imm:$imm),
		operator # "." # opsign # " $dest, $src1, $imm",
		[(set i32:$dest, (vectorIntrinsic (splat i32:$src1), (splat simm13:$imm)))],
		opcode{4-0},
		FmtB_VS>;
}

multiclass FloatCompareInst<string operator, CondCode condition, Intrinsic vectorIntrinsic,
	bits<6> opcode> {
	def SSS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$src1, ScalarReg:$src2),
		operator # ".f $dest, $src1, $src2",
		[(set i32:$dest, (setcc f32:$src1, f32:$src2, condition))],
		opcode,
		FmtA_SSS>;

	def VVV : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # ".f $dest, $src1, $src2",
		[(set v16i1:$dest, (setcc v16f32:$src1, v16f32:$src2, condition))],
		opcode,
		FmtA_VVV>;

	def VVS : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # ".f $dest, $src1, $src2",
		[(set v16i1:$dest, (setcc v16f32:$src1, (splat f32:$src2), condition))],
		opcode,
		FmtA_VVS>;

	// Intrinsic forms.  See note above.
	def VVVint : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$src1, VectorReg:$src2),
		operator # ".f $dest, $src1, $src2",
		[(set i32:$dest, (vectorIntrinsic v16f32:$src1, v16f32:$src2))],
		opcode,
		FmtA_VVV>;

	def VVSint : FormatAUnmaskedTwoOpInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$src1, ScalarReg:$src2),
		operator # ".f $dest, $src1, $src2",
		[(set i32:$dest, (vectorIntrinsic v16f32:$src1, (splat f32:$src2)))],
		opcode,
		FmtA_VVS>;
}

//////////////////////////////////////////////////////////////////
// Format C: Memory instructions
//////////////////////////////////////////////////////////////////

class CFmt<bits<4> val> {
	bits<4> Value = val;
}

def FmtC_Byte_Unsigned : CFmt<0>;
def FmtC_Byte_Signed : CFmt<1>;
def FmtC_Short_Unsigned : CFmt<2>;
def FmtC_Short_Signed : CFmt<3>;
def FmtC_Word : CFmt<4>;
def FmtC_Sync : CFmt<5>;
def FmtC_ControlReg : CFmt<6>;
def FmtC_Block : CFmt<7>;
def FmtC_BlockMasked : CFmt<8>;
def FmtC_Strided : CFmt<10>;
def FmtC_StridedMasked : CFmt<11>;
def FmtC_ScGath : CFmt<13>;
def FmtC_ScGathMasked : CFmt<14>;

class FormatCInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	CFmt fmt, bits <1> isLoad>  
	: VPInstruction<outputs, inputs, asmString, pattern> 
{

	let Inst{31} = 1;
	let Inst{29} = isLoad;
	let Inst{28-25} = fmt.Value;
	
	// XXX set hasSideEffects = 1, mayStore = 1 is !isLoad?
}

class FormatCMaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	CFmt fmt, bits <1> isLoad> 
	: FormatCInst<outputs, inputs, asmString, pattern, fmt, isLoad> 
{
	bits <20> addr;	// Is offset/ptr, this is set up by getMemoryOpValue.
	bits <5> mask;
	bits <5> srcDest;

	let Inst{24-15} = addr{14-5};
	let Inst{14-10} = mask;
	let Inst{9-5} = srcDest;
	let Inst{4-0} = addr{4-0};
}

class FormatCUnmaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	CFmt fmt, bits <1> isLoad> 
	: FormatCInst<outputs, inputs, asmString, pattern, fmt, isLoad> 
{
	bits <20> addr;	// Is offset/ptr, this is set up by getMemoryOpValue.
	bits <5> srcDest;

	let Inst{24-10} = addr{19-5};
	let Inst{9-5} = srcDest;
	let Inst{4-0} = addr{4-0};
}

multiclass ScalarLoadInst<string suffix, PatFrag op, CFmt fmt>  {
	def i : FormatCUnmaskedInst<
		(outs ScalarReg:$srcDest),
		(ins MEMri:$addr),
		"load." # suffix # " $srcDest, $addr",
		[(set i32:$srcDest, (i32 (op ADDRri:$addr)))], 
		fmt,
		1>;

	def f : FormatCUnmaskedInst<
		(outs ScalarReg:$srcDest),
		(ins MEMri:$addr),
		"load." # suffix # " $srcDest, $addr",
		[(set f32:$srcDest, (op ADDRri:$addr))],
		fmt,
		1>;
}

multiclass ScalarStoreInst<string suffix, PatFrag op, CFmt fmt>  {
	let hasSideEffects = 1, mayStore = 1 in {
		def i : FormatCUnmaskedInst<
			(outs),
			(ins ScalarReg:$srcDest, MEMri:$addr),
			"store." # suffix # " $srcDest, $addr",
			[(op i32:$srcDest, ADDRri:$addr)],
			fmt, 
			0>;

		def f : FormatCUnmaskedInst<
			(outs),
			(ins ScalarReg:$srcDest, MEMri:$addr),
			"store." # suffix # " $srcDest, $addr",
			[(op f32:$srcDest, ADDRri:$addr)],
			fmt,
			0>;
	}
}

//////////////////////////////////////////////////////////////////
// Format D (cache control)
//////////////////////////////////////////////////////////////////

class DFmt<bits<3> val> {
	bits<3> Value = val;
}

def FmtD_Preload : DFmt<0>;
def FmtD_Invalidate : DFmt<1>;
def FmtD_DFlush : DFmt<2>;
def FmtD_IInvalidate : DFmt<3>;
def FmtD_StBar : DFmt<4>;

class FormatDInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	DFmt fmt> 
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	let Inst{31-29} = 7;
	let Inst{27-25} = fmt.Value;
}

//////////////////////////////////////////////////////////////////
// Format E: Branch Instruction
//////////////////////////////////////////////////////////////////

class BranchType<bits<3> val> {
	bits<3> Value = val;
}

def BT_All : BranchType<0>;
def BT_IfFalse : BranchType<1>;
def BT_IfTrue : BranchType<2>;
def BT_Uncond : BranchType<3>;
def BT_Call : BranchType<4>;
def BT_NAll : BranchType<5>;
def BT_CallReg : BranchType<6>;

class BranchInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	BranchType type>
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	let isBranch = 1;

	bits<20> dest;

	let Inst{31-28} = 0xf;
	let Inst{27-25} = type.Value;
	let Inst{24-5} = dest;
}

class ConditionalBranchInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	BranchType type>
	: BranchInst<outputs, inputs, asmString, pattern, type>
{
	bits<5> test;

	let Inst{4-0} = test;
}

class UnconditionalBranchInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	BranchType type>
	: BranchInst<outputs, inputs, asmString, pattern, type>
{
	let Inst{4-0} = 0;
}

