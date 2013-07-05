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
def splat : SDNode<"SPISD::SPLAT", SDTypeProfile<1, 1, [SDTCisEltOfVec<1, 0>]>>;

def wrapper : SDNode<"SPISD::WRAPPER", SDTIntUnaryOp>;

def reciprocal : SDNode<"SPISD::RECIPROCAL_EST", SDTFPUnaryOp>;

def LoadLiteral : SDNode<"SPISD::LOAD_LITERAL", SDTIntUnaryOp>;

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;

def MEMri : Operand<iPTR> {
	let PrintMethod = "printMemOperand";
	let MIOperandInfo = (ops ptr_rc, i32imm);
}

def ComputeFrameAddr : Operand<iPTR> {
	let PrintMethod = "printComputeFrameAddr";
	let MIOperandInfo = (ops ptr_rc, i32imm);
}

//
// Instruction Classes
//

class VPInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: Instruction {
	let Namespace = "SP";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let AsmString = asmString;
	let Pattern = pattern;
}

class Pseudo<dag outputs, dag inputs, string asmString, list<dag> pattern>
   : VPInstruction<outputs, inputs, asmString, pattern>;

multiclass VPInfixIntArith<string operator, SDNode OpNode> {
	// Format A
	// Scalar = Scalar Op Scalar
	def SSS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, ScalarReg:$c),
		"s$dst = s$b " # operator # " s$c",
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;

	// Vector = Vector Op Vector
	def VVV : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, VectorReg:$c),
		"v$dst = v$b " # operator # " v$c",
		[(set v16i32:$dst, (OpNode v16i32:$b, v16i32:$c))]>;

	// Vector = Vector Op Scalar
	def VVS : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, ScalarReg:$c),
		"v$dst = v$b " # operator # " s$c",
		[(set v16i32:$dst, (OpNode v16i32:$b, (splat i32:$c)))]>;

	let Constraints = "$dst = $oldvalue" in {
		// Vector = Vector op Vector, masked
		def VVVM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = v$src1 " # operator # " v$src2",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode v16i32:$src1, v16i32:$src2), v16i32:$oldvalue))]>;

		// Vector = Vector Op Scalar, masked
		def VVSM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = v$src1 " # operator # " s$src2",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat i32:$src2)), v16i32:$oldvalue))]>;
	}

	// Format B
	// Scalar = Scalar Op Immediate
	def SSI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, i32imm:$c),
		"s$dst = s$b " # operator # " $c",
		[(set i32:$dst, (OpNode i32:$b, (i32 simm13:$c)))]>;

	// Vector = Vector Op Immediate
	def VVI : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, i32imm:$c),
		"v$dst = v$b " # operator # " $c",
		[(set v16i32:$dst, (OpNode v16i32:$b, (splat simm13:$c)))]>;

	// Vector = Scalar Op Immediate
	def VSI : VPInstruction<
		(outs VectorReg:$dst), 
		(ins ScalarReg:$b, i32imm:$c),
		"v$dst = s$b " # operator # " $c",
		[(set v16i32:$dst, (OpNode (splat i32:$b), (splat simm13:$c)))]>;

	let Constraints = "$dst = $oldvalue" in {
		// Vector = Vector Op Immediate, masked
		def VVIM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = v$src1 " # operator # " $imm",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode v16i32:$src1, (splat simm8:$imm)), v16i32:$oldvalue))]>;

		// Vector = Scalar Op Immediate, masked
		def VSIM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, ScalarReg:$src1, i32imm:$imm, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = v$src1 " # operator # " $imm",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode (splat i32:$src1), (splat simm8:$imm)), v16i32:$oldvalue))]>;
	}
}

multiclass VPInfixFloatArith<string operator, SDNode OpNode> 
{
	// Scalar = Scalar Op Scalar
	def SSS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, ScalarReg:$c),
		"f$dst = f$b " # operator # " f$c",
		[(set ScalarReg:$dst, (OpNode f32:$b, f32:$c))]>;

	// Vector = Vector Op Vector
	def VVV : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, VectorReg:$c),
		"vf$dst = vf$b " # operator # " vf$c",
		[(set VectorReg:$dst, (OpNode v16f32:$b, v16f32:$c))]>;

	// Vector = Vector Op Scalar
	def VVS : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, ScalarReg:$c),
		"vf$dst = vf$b " # operator # " f$c",
		[(set VectorReg:$dst, (OpNode v16f32:$b, (splat f32:$c)))]>;

	// Predicated
	let Constraints = "$dst = $oldvalue" in {
		// Vector = Vector Op Vector, masked
		def VVVM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			"vf$dst{{s$mask}} = vf$src1 " # operator # " vf$src2",
			[(set VectorReg:$dst, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				v16f32:$src2), v16f32:$oldvalue))]>;

		// Vector = Vector Op Scalar, masked
		def VVSM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, ScalarReg:$src2, VectorReg:$oldvalue),
			"vf$dst{{s$mask}} = vf$src1 " # operator # " f$src2",
			[(set v16f32:$dst, (vselect v16i1:$mask, (OpNode v16f32:$src1, 
				(splat f32:$src2)), v16f32:$oldvalue))]>;
	}
}

multiclass VPFunctionalIntArith<string operator, SDNode OpNode> {
	def S : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b),
		"s$dst = " # operator # "(s$b)",
		[(set i32:$dst, (OpNode i32:$b))]>;

	def V : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b),
		"v$dst = " # operator # "(v$b)",
		[(set v16i32:$dst, (OpNode v16i32:$b))]>;

	// Predicated
	let Constraints = "$dst = $oldvalue" in {
		def VM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = " # operator # "(v$src)",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode v16i32:$src), v16i32:$oldvalue))]>;
	}
}

multiclass VPFunctionalFloatArith<string operator, SDNode OpNode> {
	def S : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b),
		"f$dst = " # operator # "(f$b)",
		[(set f32:$dst, (OpNode f32:$b))]>;

	def V : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b),
		"vf$dst = " # operator # "(vf$b)",
		[(set v16f32:$dst, (OpNode v16f32:$b))]>;

	// Predicated
	let Constraints = "$dst = $oldvalue" in {
		def VM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src, VectorReg:$oldvalue),
			"vf$dst{{s$mask}} = " # operator # "(vf$src)",
			[(set v16f32:$dst, (vselect v16i1:$mask, (OpNode v16f32:$src), v16f32:$oldvalue))]>;
	}
}

multiclass CMPI<string operator, string opsign, CondCode condition, Intrinsic vectorIntrinsic> {
	// Instruction format A, integer
	def SSS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, ScalarReg:$b),
		"s$dst = s" # opsign # "$a " # operator # " s" # opsign # "$b",
		[(set i32:$dst, (setcc i32:$a, i32:$b, condition))]>;

	def VVV : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = v" # opsign # "$a " # operator # " v" # opsign # "$b",
		[(set v16i1:$dst, (setcc v16i32:$a, v16i32:$b, condition))]>;

	def VVS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, ScalarReg:$b),
		"s$dst = v" # opsign # "$a " # operator # " s" # opsign # "$b",
		[(set v16i1:$dst, (setcc v16i32:$a, (splat i32:$b), condition))]>;

	// Instruction format B
	def SSI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, i32imm:$b),
		"s$dst = s" # opsign # "$a " # operator # " $b",
		[(set i32:$dst, (setcc i32:$a, simm13:$b, condition))]>;

	def VVI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, i32imm:$b),
		"s$dst = v" # opsign # "$a " # operator # " $b",
		[(set v16i1:$dst, (setcc v16i32:$a, (splat simm13:$b), condition))]>;

	// Intrinsic forms
	// Ideally, vector comparisons would just use native instructions, but I had a hard 
	// time coercing that into a scalar register, so they are intrinsics for now.
	def VSI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, i32imm:$b),
		"s$dst = s" # opsign # "$a " # operator # " $b",
		[(set i32:$dst, (setcc (splat i32:$a), (splat simm13:$b), condition))]>;

	def VVVint : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = v" # opsign # "$a " # operator # " v" # opsign # "$b",
		[(set i32:$dst, (vectorIntrinsic v16i32:$a, v16i32:$b))]>;

	def VVSint : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, ScalarReg:$b),
		"s$dst = v" # opsign # "$a " # operator # " s" # opsign # "$b",
		[(set i32:$dst, (vectorIntrinsic v16i32:$a, (splat i32:$b)))]>;

	def VVIint : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, i32imm:$b),
		"s$dst = v" # opsign # "$a " # operator # " $b",
		[(set i32:$dst, (vectorIntrinsic v16i32:$a, (splat simm13:$b)))]>;

	def VSIint : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, i32imm:$b),
		"s$dst = s" # opsign # "$a " # operator # " $b",
		[(set i32:$dst, (vectorIntrinsic (splat i32:$a), (splat simm13:$b)))]>;
}

multiclass CMPF<string operator, CondCode condition, Intrinsic vectorIntrinsic> {
	def SSS : VPInstruction<
		(outs ScalarReg:$dst),
		(ins ScalarReg:$a, ScalarReg:$b),
		"s$dst = f$a " # operator # " f$b",
		[(set i32:$dst, (setcc f32:$a, f32:$b, condition))]>;

	def VVV : VPInstruction<
		(outs ScalarReg:$dst),
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = vf$a " # operator # " vf$b",
		[(set v16i1:$dst, (setcc v16f32:$a, v16f32:$b, condition))]>;

	def VVS : VPInstruction<
		(outs ScalarReg:$dst),
		(ins VectorReg:$a, ScalarReg:$b),
		"s$dst = vf$a " # operator # " f$b",
		[(set v16i1:$dst, (setcc v16f32:$a, (splat f32:$b), condition))]>;

	// Intrinsic forms.  See note above.
	def VVVint : VPInstruction<
		(outs ScalarReg:$dst),
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = vf$a " # operator # " vf$b",
		[(set i32:$dst, (vectorIntrinsic v16f32:$a, v16f32:$b))]>;

	def VVSint : VPInstruction<
		(outs ScalarReg:$dst),
		(ins VectorReg:$a, ScalarReg:$b),
		"s$dst = vf$a " # operator # " f$b",
		[(set i32:$dst, (vectorIntrinsic v16f32:$a, (splat f32:$b)))]>;
}

class BranchInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	let isBranch = 1;
	let isTerminator = 1;	// Ends current basic block and starts another one
}

multiclass SCALAR_LOAD<string suffix, string regtype, PatFrag op>  {
	def i : VPInstruction<
		(outs ScalarReg:$dst),
		(ins MEMri:$addr),
		regtype # "$dst = mem_" # suffix # "[$addr]",
		[(set i32:$dst, (i32 (op ADDRri:$addr)))]>;

	def f : VPInstruction<
		(outs ScalarReg:$dst),
		(ins MEMri:$addr),
		regtype # "$dst = mem_" # suffix # "[$addr]",
		[(set f32:$dst, (op ADDRri:$addr))]>;
}

multiclass SCALAR_STORE<string suffix, PatFrag op>  {
	let hasSideEffects = 1, mayStore = 1 in {
		def i : VPInstruction<
			(outs),
			(ins MEMri:$addr, ScalarReg:$src),
			"mem_" # suffix # "[$addr] = s$src",
			[(op i32:$src, ADDRri:$addr)]>;

		def f : VPInstruction<
			(outs),
			(ins MEMri:$addr, ScalarReg:$src),
			"mem_" # suffix # "[$addr] = s$src",
			[(op f32:$src, ADDRri:$addr)]>;
	}
}
