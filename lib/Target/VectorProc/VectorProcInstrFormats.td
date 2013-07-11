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

//
// Node types
//

def simm13  : PatLeaf<(imm), [{ return isInt<13>(N->getSExtValue()); }]>;
def simm8  : PatLeaf<(imm), [{ return isInt<8>(N->getSExtValue()); }]>;
def brtarget : Operand<OtherVT>;

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
	let MIOperandInfo = (ops ScalarReg, i32imm);
}

// XXX may be able to merge into MEMri
def ComputeFrameAddr : Operand<iPTR> {
	let PrintMethod = "printComputeFrameAddr";
	let MIOperandInfo = (ops ScalarReg, i32imm);
}

//
// Instruction Classes
//

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

class Pseudo<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	let Namespace = "VectorProc";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let Pattern = pattern;
	let isCodeGenOnly = 1;
	let isPseudo = 1;
	let Inst{31-0} = 0;
}

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
	bits <5> src1;

	let Inst{31-29} = 6;
	let Inst{28-26} = fmt.Value;
	let Inst{25-20} = opcode;
	let Inst{9-5} = dest;
	let Inst{4-0} = src1;
}

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
	bits <5> src2;

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
	def SSS : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$b, ScalarReg:$c),
		operator # " $dest, $b, $c",
		[(set i32:$dest, (OpNode i32:$b, i32:$c))],
		opcode,
		FmtA_SSS>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}

	// Vector = Vector Op Vector
	def VVV : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b, VectorReg:$c),
		operator # " $dest, $b, $c",
		[(set v16i32:$dest, (OpNode v16i32:$b, v16i32:$c))],
		opcode,
		FmtA_VVV>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}

	// Vector = Vector Op Scalar
	def VVS : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b, ScalarReg:$c),
		operator # " $dest, $b, $c",
		[(set v16i32:$dest, (OpNode v16i32:$b, (splat i32:$c)))],
		opcode,
		FmtA_VVS>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}

	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector op Vector, masked
		def VVVM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, v16i32:$src2), v16i32:$oldvalue))],
			opcode,
			FmtA_VVVM>
		{
			bits <5> src2;
			bits <5> mask;
			let Inst{19-15} = src2;
			let Inst{14-10} = mask;
		}

		// Vector = Vector Op Scalar, masked
		def VVSM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $src2",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat i32:$src2)), v16i32:$oldvalue))],
			opcode,
			FmtA_VVSM>
		{
			bits <5> src2;
			bits <5> mask;
			let Inst{19-15} = src2;
			let Inst{14-10} = mask;
		}
	}

	// Format B
	// Scalar = Scalar Op Immediate
	def SSI : FormatBUnmaskedInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$b, i32imm:$c),
		operator # " $dest, $b, $c",
		[(set i32:$dest, (OpNode i32:$b, (i32 simm13:$c)))],
		opcode{4-0},
		FmtB_SS>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}
	
	// Vector = Vector Op Immediate
	def VVI : FormatBUnmaskedInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b, i32imm:$c),
		operator # " $dest, $b, $c",
		[(set v16i32:$dest, (OpNode v16i32:$b, (splat simm13:$c)))],
		opcode{4-0},
		FmtB_VV>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}

	// Vector = Scalar Op Immediate
	def VSI : FormatBUnmaskedInst<
		(outs VectorReg:$dest), 
		(ins ScalarReg:$b, i32imm:$c),
		operator # " $dest, $b, $c",
		[(set v16i32:$dest, (OpNode (splat i32:$b), (splat simm13:$c)))],
		opcode{4-0},
		FmtB_VS>
	{
		bits <5> src2;
		let Inst{19-15} = src2;
	}

	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector Op Immediate, masked
		def VVIM : FormatBMaskedInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $imm",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat simm8:$imm)), v16i32:$oldvalue))],
			opcode{4-0},
			FmtB_VVM>
		{
			bits <5> src2;
			bits <5> mask;
			let Inst{19-15} = src2;
			let Inst{14-10} = mask;
		}

		// Vector = Scalar Op Immediate, masked
		def VSIM : FormatBMaskedInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, ScalarReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $imm",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode (splat i32:$src1), (splat simm8:$imm)), v16i32:$oldvalue))],
			opcode{4-0},
			FmtB_VSM>
		{
			bits <5> src2;
			bits <5> mask;
			let Inst{19-15} = src2;
			let Inst{14-10} = mask;
		}
	}
}

multiclass TwoOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> 
{
	// Scalar = Scalar Op Scalar
	def SSS : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$b, ScalarReg:$c),
		operator # " $dest, $b, $c",
		[(set ScalarReg:$dest, (OpNode f32:$b, f32:$c))],
		opcode,
		FmtA_SSS>;

	// Vector = Vector Op Vector
	def VVV : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b, VectorReg:$c),
		operator # " $dest, $b, $c",
		[(set VectorReg:$dest, (OpNode v16f32:$b, v16f32:$c))],
		opcode,
		FmtA_VVV>;

	// Vector = Vector Op Scalar
	def VVS : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b, ScalarReg:$c),
		operator # " $dest, $b, $c",
		[(set VectorReg:$dest, (OpNode v16f32:$b, (splat f32:$c)))],
		opcode,
		FmtA_VVS>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		// Vector = Vector Op Vector, masked
		def VVVM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $src2",
			[(set VectorReg:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				v16f32:$src2), v16f32:$oldvalue))],
			opcode,
			FmtA_VVVM>;
		
		// Vector = Vector Op Scalar, masked
		def VVSM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src1, $src2",
			[(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				(splat f32:$src2)), v16f32:$oldvalue))],
			opcode,
			FmtA_VVSM>;
	}
}

multiclass OneOpIntArith<string operator, SDNode OpNode, bits<6> opcode> {
	def S : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$b),
		operator # " $dest, $b",
		[(set i32:$dest, (OpNode i32:$b))],
		opcode,
		FmtA_SSS>;

	def V : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b),
		operator # " $dest, $b",
		[(set v16i32:$dest, (OpNode v16i32:$b))],
		opcode,
		FmtA_VVV>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		def VM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$src, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $src",
			[(set v16i32:$dest, (vselect v16i1:$mask, (OpNode v16i32:$src), v16i32:$oldvalue))],
			opcode,
			FmtA_VVVM>;
	}
}

multiclass OneOpFloatArith<string operator, SDNode OpNode, bits<6> opcode> {
	def S : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$b),
		operator # " $dest, $b",
		[(set f32:$dest, (OpNode f32:$b))],
		opcode,
		FmtA_SSS>;

	def V : FormatAInst<
		(outs VectorReg:$dest), 
		(ins VectorReg:$b),
		operator # " $dest, $b",
		[(set v16f32:$dest, (OpNode v16f32:$b))],
		opcode,
		FmtA_VVV>;

	// Predicated
	let Constraints = "$dest = $oldvalue" in {
		def VM : FormatAInst<
			(outs VectorReg:$dest),
			(ins ScalarReg:$mask, VectorReg:$b, VectorReg:$oldvalue),
			operator # " $dest {{ $mask }}, $b",
			[(set v16f32:$dest, (vselect v16i1:$mask, (OpNode v16f32:$b), v16f32:$oldvalue))],
			opcode,
			FmtA_VVVM>;
	}
}

multiclass IntCompareInst<string operator, string opsign, CondCode condition, Intrinsic vectorIntrinsic,
	bits<6> opcode> {
	// Instruction format A, integer
	def SSS : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$a, ScalarReg:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (setcc i32:$a, i32:$b, condition))],
		opcode,
		FmtA_SSS>;

	def VVV : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, VectorReg:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set v16i1:$dest, (setcc v16i32:$a, v16i32:$b, condition))],
		opcode,
		FmtA_VVV>;

	def VVS : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, ScalarReg:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set v16i1:$dest, (setcc v16i32:$a, (splat i32:$b), condition))],
		opcode,
		FmtA_VVS>;

	// Instruction format B
	def SSI : FormatBInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$a, i32imm:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (setcc i32:$a, simm13:$b, condition))],
		opcode{4-0},
		FmtB_SS>;

	def VVI : FormatBInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, i32imm:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set v16i1:$dest, (setcc v16i32:$a, (splat simm13:$b), condition))],
		opcode{4-0},
		FmtB_VV>;

	def VSI : FormatBInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$a, i32imm:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (setcc (splat i32:$a), (splat simm13:$b), condition))],
		opcode{4-0},
		FmtB_VS>;

	// Intrinsic forms
	// Ideally, vector comparisons would just use native instructions, but I had a hard 
	// time coercing that into a scalar register, so they are intrinsics for now.

	def VVVint : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, VectorReg:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic v16i32:$a, v16i32:$b))],
		opcode,
		FmtA_VVV>;

	def VVSint : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, ScalarReg:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic v16i32:$a, (splat i32:$b)))],
		opcode,
		FmtA_VVS>;

	def VVIint : FormatBInst<
		(outs ScalarReg:$dest), 
		(ins VectorReg:$a, i32imm:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic v16i32:$a, (splat simm13:$b)))],
		opcode{4-0},
		FmtB_VV>;

	def VSIint : FormatBInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$a, i32imm:$b),
		operator # "." # opsign # " $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic (splat i32:$a), (splat simm13:$b)))],
		opcode{4-0},
		FmtB_VS>;
}

multiclass FloatCompareInst<string operator, CondCode condition, Intrinsic vectorIntrinsic,
	bits<6> opcode> {
	def SSS : FormatAInst<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$a, ScalarReg:$b),
		operator # ".f $dest, $a, $b",
		[(set i32:$dest, (setcc f32:$a, f32:$b, condition))],
		opcode,
		FmtA_SSS>;

	def VVV : FormatAInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$a, VectorReg:$b),
		operator # ".f $dest, $a, $b",
		[(set v16i1:$dest, (setcc v16f32:$a, v16f32:$b, condition))],
		opcode,
		FmtA_VVV>;

	def VVS : FormatAInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$a, ScalarReg:$b),
		operator # ".f $dest, $a, $b",
		[(set v16i1:$dest, (setcc v16f32:$a, (splat f32:$b), condition))],
		opcode,
		FmtA_VVS>;

	// Intrinsic forms.  See note above.
	def VVVint : FormatAInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$a, VectorReg:$b),
		operator # ".f $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic v16f32:$a, v16f32:$b))],
		opcode,
		FmtA_VVV>;

	def VVSint : FormatAInst<
		(outs ScalarReg:$dest),
		(ins VectorReg:$a, ScalarReg:$b),
		operator # ".f $dest, $a, $b",
		[(set i32:$dest, (vectorIntrinsic v16f32:$a, (splat f32:$b)))],
		opcode,
		FmtA_VVS>;
}

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
	let isTerminator = 1;	// Ends current basic block and starts another one

	bits<20> targetOffset;

	let Inst{31-28} = 0xf;
	let Inst{27-25} = type.Value;
	// XXX 4-0 is the source register for some instructions.
	let Inst{24-5} = targetOffset;
}

/// XXX need FormatCInst

class CFmt<bits<4> val> {
	bits<4> Value = val;
}

def FmtC_Byte_Signed : CFmt<0>;
def FmtC_Byte_Unsigned : CFmt<1>;
def FmtC_Short_Signed : CFmt<2>;
def FmtC_Short_Unsigned : CFmt<3>;
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

	let Inst{31-30} = 2;
	let Inst{29} = isLoad;
	let Inst{28-25} = fmt.Value;
	
	// XXX set hasSideEffects = 1, mayStore = 1 is !isLoad?
}

class FormatCMaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	CFmt fmt, bits <1> isLoad> 
	: FormatCInst<outputs, inputs, asmString, pattern, fmt, isLoad> 
{
	bits <5> ptr;
	bits <10> offset;
	bits <5> mask;
	bits <5> srcDest;

	let Inst{24-15} = offset;
	let Inst{14-10} = mask;
	let Inst{9-5} = srcDest;
	let Inst{4-0} = ptr;
}

class FormatCUnmaskedInst<dag outputs, dag inputs, string asmString, list<dag> pattern,
	CFmt fmt, bits <1> isLoad> 
	: FormatCInst<outputs, inputs, asmString, pattern, fmt, isLoad> 
{
	bits <15> offset;
	bits <5> srcDest;
	bits <5> ptr;

	let Inst{24-10} = offset;
	let Inst{9-5} = srcDest;
	let Inst{4-0} = ptr;
}

multiclass ScalarLoadInst<string suffix, PatFrag op, CFmt fmt>  {
	def i : FormatCUnmaskedInst<
		(outs ScalarReg:$dest),
		(ins MEMri:$addr),
		"load." # suffix # " $dest, $addr",
		[(set i32:$dest, (i32 (op ADDRri:$addr)))], 
		fmt,
		1>;

	def f : FormatCUnmaskedInst<
		(outs ScalarReg:$dest),
		(ins MEMri:$addr),
		"load." # suffix # " $dest, $addr",
		[(set f32:$dest, (op ADDRri:$addr))],
		fmt,
		1>;
}

multiclass ScalarStoreInst<string suffix, PatFrag op, CFmt fmt>  {
	let hasSideEffects = 1, mayStore = 1 in {
		def i : FormatCUnmaskedInst<
			(outs),
			(ins MEMri:$addr, ScalarReg:$src),
			"store." # suffix # " $src, $addr",
			[(op i32:$src, ADDRri:$addr)],
			fmt, 
			0>;

		def f : FormatCUnmaskedInst<
			(outs),
			(ins MEMri:$addr, ScalarReg:$src),
			"store." # suffix # " $src, $addr",
			[(op f32:$src, ADDRri:$addr)],
			fmt,
			0>;
	}
}
