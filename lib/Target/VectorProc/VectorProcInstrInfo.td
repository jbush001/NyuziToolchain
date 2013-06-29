//===-- VectorProcInstrInfo.td - Target Description for VectorProc Target -----------===//
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


def simm13  : PatLeaf<(imm), [{ return isInt<13>(N->getSExtValue()); }]>;

class VPInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: Instruction {
	let Namespace = "SP";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let AsmString = asmString;
	let Pattern = pattern;
}

multiclass VPInfixIntArith<string operator, SDNode OpNode> {
	// Instruction format A, integer
	def SS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, ScalarReg:$c),
		"s$dst = s$b " # operator # " s$c",
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;

	// Vector/Vector
	def VV : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, VectorReg:$c),
		"v$dst = v$b " # operator # " v$c",
		[(set v16i32:$dst, (OpNode v16i32:$b, v16i32:$c))]>;

	// Predicated Vector/Vector
	let Constraints = "$dst = $oldvalue" in {
		def VVM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			"v$dst{{s$mask}} = v$src1 " # operator # " v$src2",
			[(set v16i32:$dst, (vselect v16i1:$mask, (OpNode v16i32:$src1, v16i32:$src2), v16i32:$oldvalue))]>;
	}

	// Instruction format B
	def SI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, i32imm:$c),
		"s$dst = s$b " # operator # " $c",
		[(set i32:$dst, (OpNode i32:$b, (i32 simm13:$c)))]>;
}

multiclass VPInfixFloatArith<string operator, SDNode OpNode> 
{
	def SS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$b, ScalarReg:$c),
		"f$dst = f$b " # operator # " f$c",
		[(set ScalarReg:$dst, (OpNode f32:$b, f32:$c))]>;

	def VV : VPInstruction<
		(outs VectorReg:$dst), 
		(ins VectorReg:$b, VectorReg:$c),
		"vf$dst = vf$b " # operator # " vf$c",
		[(set VectorReg:$dst, (OpNode v16f32:$b, v16f32:$c))]>;

	// Predicated
	let Constraints = "$dst = $oldvalue" in {
		def VVM : VPInstruction<
			(outs VectorReg:$dst),
			(ins ScalarReg:$mask, VectorReg:$src1, VectorReg:$src2, VectorReg:$oldvalue),
			"vf$dst{{s$mask}} = vf$src1 " # operator # " vf$src2",
			[(set VectorReg:$dst, (vselect v16i1:$mask, (OpNode (v16f32 VectorReg:$src1), 
				(v16f32 VectorReg:$src2)), VectorReg:$oldvalue))]>;
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
		"s$dst = " # operator # "(s$b)",
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

defm AND    : VPInfixIntArith<"&", and>;
defm OR     : VPInfixIntArith<"|", or>;
defm XOR    : VPInfixIntArith<"^", xor>;
defm SLL    : VPInfixIntArith<"<<", shl>;
defm SRL    : VPInfixIntArith<">>", srl>;
defm SRA    : VPInfixIntArith<">>", sra>;	// XXX need to use U register.
defm ADDI   : VPInfixIntArith<"+", add>;
defm SUBI   : VPInfixIntArith<"-", sub>;
defm SMULI  : VPInfixIntArith  <"*", mul>;
defm ADDF   : VPInfixFloatArith<"+", fadd>;
defm SUBF   : VPInfixFloatArith<"-", fsub>;
defm MULF   : VPInfixFloatArith<"*", fmul>;
defm CLZ 	: VPFunctionalIntArith<"clz", ctlz>;
defm CTZ 	: VPFunctionalIntArith<"ctz", cttz>;
defm CLZ_ZU	: VPFunctionalIntArith<"clz", ctlz_zero_undef>;
defm CTZ_ZU	: VPFunctionalIntArith<"ctz", cttz_zero_undef>;

def SEXT16 : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$src),
		"s$dst = sext16(s$src)",
		[(set ScalarReg:$dst, (sext_inreg i32:$src, i16))]>;

def SEXT8 : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$src),
		"s$dst = sext8(s$src)",
		[(set ScalarReg:$dst, (sext_inreg i32:$src, i8))]>;

// XXX need vector versions of these
def SITOF : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
            "f$dst = itof(s$src)",
        	[(set f32:$dst, (sint_to_fp i32:$src))]>;

def FTOSI : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
        	"s$dst = ftoi(f$src)",
        	[(set i32:$dst, (fp_to_sint f32:$src))]>;

def MOVEREG : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
        	"s$dst = s$src",
        	[]>;

def brtarget : Operand<OtherVT>;

multiclass CMPI<string operator, string opsign, CondCode condition> {
	// Instruction format A, integer
	def SS : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, ScalarReg:$b),
		"s$dst = s" # opsign # "$a " # operator # " s" # opsign # "$b",
		[(set i32:$dst, (setcc i32:$a, i32:$b, condition))]>;

	def VV : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = v" # opsign # "$a " # operator # " v" # opsign # "$b",
		[(set v16i1:$dst, (setcc v16i32:$a, v16i32:$b, condition))]>;

	// Instruction format B
	def SI : VPInstruction<
		(outs ScalarReg:$dst), 
		(ins ScalarReg:$a, i32imm:$b),
		"s$dst = s" # opsign # "$a " # operator # " $b",
		[(set i32:$dst, (setcc i32:$a, simm13:$b, condition))]>;
}

multiclass CMPF<string operator, CondCode condition> {
	def SS : VPInstruction<
		(outs ScalarReg:$dst),
		(ins ScalarReg:$a, ScalarReg:$b),
		"s$dst = f$a " # operator # " f$b",
		[(set i32:$dst, (setcc f32:$a, f32:$b, condition))]>;

	def VV : VPInstruction<
		(outs ScalarReg:$dst),
		(ins VectorReg:$a, VectorReg:$b),
		"s$dst = vf$a " # operator # " vf$b",
		[(set v16i1:$dst, (setcc v16f32:$a, v16f32:$b, condition))]>;
}

defm SGTSI : CMPI<">", "", SETGT>;	
defm SGESI : CMPI<">=", "", SETGE>;
defm SLTSI : CMPI<"<", "", SETLT>;
defm SLESI : CMPI<"<=", "", SETLE>;
defm SEQSI : CMPI<"==", "", SETEQ>;
defm SNESI : CMPI<"<>", "", SETNE>;
defm SGTUI : CMPI<">", "u", SETUGT>;	
defm SGEUI : CMPI<">=", "u", SETUGE>;
defm SLTUI : CMPI<"<", "u", SETULT>;
defm SLEUI : CMPI<"<=", "u", SETULE>;
defm SGTFO : CMPF<">", SETOGT>;	// Note: unordered and ordered treated the same
defm SGEFO : CMPF<">=", SETOGE>;
defm SLTFO : CMPF<"<", SETOLT>;
defm SLEFO : CMPF<"<=", SETOLE>;
defm SEQFO : CMPF<"==", SETOEQ>;
defm SNEFO : CMPF<"<>", SETONE>;
defm SGTFU : CMPF<">", SETUGT>;
defm SGEFU : CMPF<">=", SETUGE>;
defm SLTFU : CMPF<"<", SETULT>;
defm SLEFU : CMPF<"<=", SETULE>;
defm SEQFU : CMPF<"==", SETUEQ>;
defm SNEFU : CMPF<"<>", SETUNE>;

class BranchInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: VPInstruction<outputs, inputs, asmString, pattern>
{
	let isBranch = 1;
	let isTerminator = 1;	// Ends current basic block and starts another one
}

let isBarrier = 1 in {
	def GOTO : BranchInstruction<
		(outs),
		(ins brtarget:$offset),
		"goto $offset",
		[(br bb:$offset)]>;
}

def IFFALSE	: BranchInstruction<
	(outs), 
	(ins ScalarReg:$rs, brtarget:$offset),
	"if !s$rs goto $offset",
	[(brcond (i32 (seteq i32:$rs, 0)), bb:$offset)]> ;

def IFTRUE	: BranchInstruction<
	(outs), 
	(ins ScalarReg:$rs, brtarget:$offset),
	"if s$rs goto $offset",
	[(brcond i32:$rs, bb:$offset)]> ;

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;

def MEMri : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, i32imm);
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

def BLOCK_STOREI : VPInstruction<
	(outs),
	(ins MEMri:$addr, VectorReg:$src),
	"mem_l[$addr] = v$src",
	[(store v16i32:$src, ADDRri:$addr)]>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_STOREF : VPInstruction<
	(outs),
	(ins MEMri:$addr, VectorReg:$src),
	"mem_l[$addr] = v$src",
	[(store v16f32:$src, ADDRri:$addr)]>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_LOADI : VPInstruction<
	(outs VectorReg:$dest),
	(ins MEMri:$addr),
	"v$dest = mem_l[$addr]",
	[(set v16i32:$dest, (load ADDRri:$addr))]>;

def BLOCK_LOADF : VPInstruction<
	(outs VectorReg:$dest),
	(ins MEMri:$addr),
	"v$dest = mem_l[$addr]",
	[(set v16f32:$dest, (load ADDRri:$addr))]>;

defm LBS : SCALAR_LOAD<"b", "s", sextloadi8>;
defm LBU : SCALAR_LOAD<"b", "u", zextloadi8>;
defm LSS : SCALAR_LOAD<"s", "s", sextloadi16>;
defm LSU : SCALAR_LOAD<"s", "u", zextloadi16>;
defm LW : SCALAR_LOAD<"l", "s", load>;
defm SB : SCALAR_STORE<"b", truncstorei8>;
defm SS : SCALAR_STORE<"s", truncstorei16>;
defm SW : SCALAR_STORE<"l", store>;

// A bit of a kludge.  Used to store the result of a vector comparison. 
// The compiler does this in some cases and the normal store does not match it.
def STORE_MASK : VPInstruction<
	(outs),
	(ins MEMri:$addr, ScalarReg:$src),
	"mem_l[$addr] = u$src",
	[(store v16i1:$src, ADDRri:$addr)]>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSSi ADDRri:$src)>;

def GET_FIELD : VPInstruction<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"s$dest = getfield(v$src, s$index)",
	[(set i32:$dest, (extractelt v16i32:$src, i32:$index))]>;

def SHUFFLE : VPInstruction<
	(outs VectorReg:$dest),
	(ins VectorReg:$src, VectorReg:$indices),
	"v$dest = shuffle(v$src, v$indices)",
	[(set v16i32:$dest, (vector_shuffle v16i32:$src, v16i32:$indices))]>;

def LOADIMM : VPInstruction<
	(outs ScalarReg:$dest),
	(ins i32imm:$val),
	"s$dest = $val",
	[(set i32:$dest, imm:$val)]>;

def SDT_SPRet : SDTypeProfile<0, 1, [SDTCisVT<0, i32>]>;

def retflag : SDNode<"SPISD::RET_FLAG", 
	SDT_SPRet,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

let isReturn = 1, isTerminator = 1, Uses = [S30] in {
	def RET : VPInstruction<
		(outs),
		(ins i32imm:$val),
		"pc = link",
		[(retflag simm13:$val)]>;
}

def SDT_SPCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_SPCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SPCallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_SPCallSeqEnd,
                           [SDNPHasChain, SDNPSideEffect, SDNPOptInGlue, SDNPOutGlue]>;

let Defs = [S29], Uses = [S29], hasSideEffects = 1 in {
	def ADJCALLSTACKDOWN : VPInstruction<(outs), (ins i32imm:$amt),
								   "; ADJCALLSTACKDOWN $amt",
								   [(callseq_start timm:$amt)]>;
	def ADJCALLSTACKUP : VPInstruction<(outs), (ins i32imm:$amt1, i32imm:$amt2),
								"; ADJCALLSTACKUP $amt1",
								[(callseq_end timm:$amt1, timm:$amt2)]>;
}

def calltarget : Operand<i32>;
def SDT_SPCall : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;
def call       : SDNode<"SPISD::CALL", SDT_SPCall,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                            SDNPVariadic]>;

let isCall = 1, Defs = [S0, S1, S2, S3, S4, S30 ] in {
  def CALL : VPInstruction<
  	(outs), 
  	(ins calltarget:$dst, variable_ops),
	"call $dst", 
	[]>;

  def JMPLri : VPInstruction<
  		(outs), 
  		(ins MEMri:$ptr, variable_ops),
        "call $ptr",
        [(call ADDRri:$ptr)]>;
}

def : Pat<(call tglobaladdr:$dst),
          (CALL tglobaladdr:$dst)>;
def : Pat<(call texternalsym:$dst),
          (CALL texternalsym:$dst)>;

def LoadLiteral : SDNode<"SPISD::LOAD_LITERAL", SDTIntUnaryOp>;

def LEA : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"s$dest = &$label",
	[(set i32:$dest, (LoadLiteral tglobaladdr:$label))]>;


// Intrinsics
def GET_CURRENT_STRAND : VPInstruction<
	(outs ScalarReg:$dest),
	(ins),
	"s$dest = cr0",
	[(set i32:$dest, (int_vp_get_current_strand))]>;

// XXXX need pattern fragment for VMUX

def INT_GATHER_LOADI : VPInstruction<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr),
	"v$dest = mem_l[v$ptr]",
	[(set v16i32:$dest, (int_vp_gather_loadi v16i32:$ptr))]>;

def INT_GATHER_LOADF : VPInstruction<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr),
	"vf$dest = mem_l[v$ptr]",
	[(set v16f32:$dest, (int_vp_gather_loadf v16i32:$ptr))]>;

def INT_GATHER_LOADI_MASKED : VPInstruction<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"v$dest{{s$mask}} = mem_l[v$ptr]",
	[(set v16i32:$dest, (int_vp_gather_loadi_masked v16i32:$ptr, i32:$mask))]>;

def INT_GATHER_LOADF_MASKED : VPInstruction<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"vf$dest{{s$mask}} = mem_l[v$ptr]",
	[(set v16f32:$dest, (int_vp_gather_loadf_masked v16i32:$ptr, i32:$mask))]>;

def INT_BLOCK_LOADI_MASKED : VPInstruction<
	(outs VectorReg:$dest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"v$dest{{s$mask}} = mem_l[s$ptr]",
	[(set v16i32:$dest, (int_vp_block_loadi_masked i32:$ptr, i32:$mask))]>;

def INT_BLOCK_LOADF_MASKED : VPInstruction<
	(outs VectorReg:$dest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"vf$dest{{s$mask}} = mem_l[s$ptr]",
	[(set v16f32:$dest, (int_vp_block_loadf_masked i32:$ptr, i32:$mask))]>;

let hasSideEffects = 1, mayStore = 1 in {
	def INT_SCATTER_STOREI : VPInstruction<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value),
		"mem_l[v$ptr] = v$value",
		[(int_vp_scatter_storei v16i32:$ptr, v16i32:$value)]>;

	def INT_SCATTER_STOREF : VPInstruction<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value),
		"mem_l[v$ptr] = v$value",
		[(int_vp_scatter_storef v16i32:$ptr, v16f32:$value)]>;

	def INT_SCATTER_STOREI_MASKED : VPInstruction<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[v$ptr]{{s$mask}} = v$value",
		[(int_vp_scatter_storei_masked v16i32:$ptr, v16i32:$value, i32:$mask)]>;

	def INT_SCATTER_STOREF_MASKED : VPInstruction<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[v$ptr]{{s$mask}} = v$value",
		[(int_vp_scatter_storef_masked v16i32:$ptr, v16f32:$value, i32:$mask)]>;

	def INT_BLOCK_STOREI_MASKED : VPInstruction<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[s$ptr]{{s$mask}} = v$value",
		[(int_vp_block_storei_masked i32:$ptr, v16i32:$value, i32:$mask)]>;

	def INT_BLOCK_STOREF_MASKED : VPInstruction<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[s$ptr]{{s$mask}} = v$value",
		[(int_vp_block_storef_masked i32:$ptr, v16f32:$value, i32:$mask)]>;
}
