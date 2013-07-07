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


//////////////////////////////////////////////////////////////////
// Arithmetic (Format A & B)
//////////////////////////////////////////////////////////////////

defm AND    : InfixIntArithInst<"&", and, 0x01>;
defm OR     : InfixIntArithInst<"|", or, 0x00>;
defm XOR    : InfixIntArithInst<"^", xor, 0x03>;
defm SLL    : InfixIntArithInst<"<<", shl, 0x0b>;
defm SRL    : InfixIntArithInst<">>", srl, 0x0a>;
defm SRA    : InfixIntArithInst<">>", sra, 0x09>;	// XXX need to use U register.
defm ADDI   : InfixIntArithInst<"+", add, 0x05>;
defm SUBI   : InfixIntArithInst<"-", sub, 0x06>;
defm SMULI  : InfixIntArithInst  <"*", mul, 0x07>;
defm ADDF   : InfixFloatArithInst<"+", fadd, 0x20>;
defm SUBF   : InfixFloatArithInst<"-", fsub, 0x21>;
defm MULF   : InfixFloatArithInst<"*", fmul, 0x22>;
defm CLZ 	: FunctionalIntArithInst<"clz", ctlz, 0x0c>;
defm CTZ 	: FunctionalIntArithInst<"ctz", cttz, 0x0e>;
defm CLZ_ZU	: FunctionalIntArithInst<"clz", ctlz_zero_undef, 0x0c>;
defm CTZ_ZU	: FunctionalIntArithInst<"ctz", cttz_zero_undef, 0x0e>;
defm RECIP  : FunctionalFloatArithInst<"reciprocal", reciprocal, 0x1c>;

def SEXT16 : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src),
		"s$dest = sext16(s$src)",
		[(set ScalarReg:$dest, (sext_inreg i32:$src, i16))],
		0x1e,
		FmtA_SSS>;

def SEXT8 : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src),
		"s$dest = sext8(s$src)",
		[(set ScalarReg:$dest, (sext_inreg i32:$src, i8))],
		0x1d,
		FmtA_SSS>;

// XXX need predicated versions of these
def SITOF : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
            "f$dest = itof(s$src)",
        	[(set f32:$dest, (sint_to_fp i32:$src))],
        	0x2a,
        	FmtA_SSS>;

def SITOFV : FormatAInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src),
            "vf$dest = itof(v$src)",
        	[(set v16f32:$dest, (sint_to_fp v16i32:$src))],
        	0x2a,
        	FmtA_VVV>;

def FTOSI : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
        	"s$dest = ftoi(f$src)",
        	[(set i32:$dest, (fp_to_sint f32:$src))],
        	0x1b,
        	FmtA_SSS>;

def FTOSIV : FormatAInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src),
        	"v$dest = ftoi(vf$src)",
        	[(set v16i32:$dest, (fp_to_sint v16f32:$src))],
        	0x1b,
        	FmtA_VVV>;

def MOVEREG : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
        	"s$dest = s$src",
        	[],
        	0x0f,
        	FmtA_SSS>;

defm SGTSI : IntCompareInst<">", "", SETGT, int_vp_mask_cmpi_sgt, 0x12>;	
defm SGESI : IntCompareInst<">=", "", SETGE, int_vp_mask_cmpi_sge, 0x13>;
defm SLTSI : IntCompareInst<"<", "", SETLT, int_vp_mask_cmpi_slt, 0x14>;
defm SLESI : IntCompareInst<"<=", "", SETLE, int_vp_mask_cmpi_sle, 0x15>;
defm SEQSI : IntCompareInst<"==", "", SETEQ, int_vp_mask_cmpi_eq, 0x10>;
defm SNESI : IntCompareInst<"<>", "", SETNE, int_vp_mask_cmpi_ne, 0x11>;
defm SGTUI : IntCompareInst<">", "u", SETUGT, int_vp_mask_cmpi_ugt, 0x16>;	
defm SGEUI : IntCompareInst<">=", "u", SETUGE, int_vp_mask_cmpi_uge, 0x17>;
defm SLTUI : IntCompareInst<"<", "u", SETULT, int_vp_mask_cmpi_ult, 0x18>;
defm SLEUI : IntCompareInst<"<=", "u", SETULE, int_vp_mask_cmpi_ule, 0x19>;

// Note: unordered and ordered treated the same
defm SGTFO : FloatCompareInst<">", SETOGT, int_vp_mask_cmpf_gt, 0x2c>;	
defm SGEFO : FloatCompareInst<">=", SETOGE, int_vp_mask_cmpf_ge, 0x2d>;
defm SLTFO : FloatCompareInst<"<", SETOLT, int_vp_mask_cmpf_lt, 0x2e>;
defm SLEFO : FloatCompareInst<"<=", SETOLE, int_vp_mask_cmpf_le, 0x2f>;
defm SEQFO : FloatCompareInst<"==", SETOEQ, int_vp_mask_cmpf_eq, 0x10>;
defm SNEFO : FloatCompareInst<"<>", SETONE, int_vp_mask_cmpf_ne, 0x11>;
defm SGTFU : FloatCompareInst<">", SETUGT, int_vp_mask_cmpf_gt, 0x2c>;
defm SGEFU : FloatCompareInst<">=", SETUGE, int_vp_mask_cmpf_ge, 0x2d>;
defm SLTFU : FloatCompareInst<"<", SETULT, int_vp_mask_cmpf_lt, 0x2e>;
defm SLEFU : FloatCompareInst<"<=", SETULE, int_vp_mask_cmpf_le, 0x2f>;
defm SEQFU : FloatCompareInst<"==", SETUEQ, int_vp_mask_cmpf_eq, 0x10>;
defm SNEFU : FloatCompareInst<"<>", SETUNE, int_vp_mask_cmpf_ne, 0x11>;

def GET_FIELDI : FormatAInst<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"s$dest = getfield(v$src, s$index)",
	[(set i32:$dest, (extractelt v16i32:$src, i32:$index))],
	0x1a,
	FmtA_VVV>;

def GET_FIELDF : FormatAInst<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"f$dest = getfield(vf$src, s$index)",
	[(set f32:$dest, (extractelt v16f32:$src, i32:$index))],
	0x1a,
	FmtA_VVV>;

def SHUFFLE : FormatAInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$src, VectorReg:$indices),
	"v$dest = shuffle(v$src, v$indices)",
	[(set v16i32:$dest, (vector_shuffle v16i32:$src, v16i32:$indices))],
	0x0d,
	FmtA_VVV>;

def CLONE_SCALARI : FormatAInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"v$dest = s$src",
	[(set v16i32:$dest, (splat i32:$src))],
	0x0f,
	FmtA_VVS>;

def CLONE_SCALARF : FormatAInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"vf$dest = f$src",
	[(set v16f32:$dest, (splat f32:$src))],
	0x0f,
	FmtA_VVS>;

let Constraints = "$dest = $oldvalue" in {
	def INSERT_VECTORI : FormatAInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"v$dest{{s$mask}} = s$newLane",
		[(set v16i32:$dest, (vselect i32:$mask, (splat i32:$newLane), v16i32:$oldvalue))],
		0x0f,
		FmtA_VVS>;

	def INSERT_VECTORF : FormatAInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"vf$dest{{s$mask}} = f$newLane",
		[(set v16f32:$dest, (vselect i32:$mask, (splat f32:$newLane), v16f32:$oldvalue))],
		0x0f,
		FmtA_VVS>;
}

//////////////////////////////////////////////////////////////////
// Memory Access (Format C)
//////////////////////////////////////////////////////////////////

def BLOCK_STOREI : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$addr, VectorReg:$src),
	"mem_l[$addr] = v$src",
	[(store v16i32:$src, ADDRri:$addr)],
	FmtC_Block,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_STOREF : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$addr, VectorReg:$src),
	"mem_l[$addr] = v$src",
	[(store v16f32:$src, ADDRri:$addr)],
	FmtC_Block,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$dest),
	(ins MEMri:$addr),
	"v$dest = mem_l[$addr]",
	[(set v16i32:$dest, (load ADDRri:$addr))],
	FmtC_Block,
	1>;

def BLOCK_LOADF : FormatCUnmaskedInst<
	(outs VectorReg:$dest),
	(ins MEMri:$addr),
	"v$dest = mem_l[$addr]",
	[(set v16f32:$dest, (load ADDRri:$addr))],
	FmtC_Block,
	1>;

defm LBS : ScalarLoadInst<"b", "s", sextloadi8, FmtC_Byte_Signed>;
defm LBU : ScalarLoadInst<"b", "u", zextloadi8, FmtC_Byte_Unsigned>;
defm LSS : ScalarLoadInst<"s", "s", sextloadi16, FmtC_Short_Signed>;
defm LSU : ScalarLoadInst<"s", "u", zextloadi16, FmtC_Short_Unsigned>;
defm LW : ScalarLoadInst<"l", "s", load, FmtC_Word>;
defm SB : ScalarStoreInst<"b", truncstorei8, FmtC_Byte_Signed>;
defm SS : ScalarStoreInst<"s", truncstorei16, FmtC_Short_Signed>;
defm SW : ScalarStoreInst<"l", store, FmtC_Word>;

// A bit of a kludge.  Used to store the result of a vector comparison. 
// The compiler does this in some cases and the normal store does not match it.
def STORE_MASK : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$addr, ScalarReg:$src),
	"mem_l[$addr] = u$src",
	[(store v16i1:$src, ADDRri:$addr)],
	FmtC_Word,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSSi ADDRri:$src)>;

def INT_GATHER_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr),
	"v$dest = mem_l[v$ptr]",
	[(set v16i32:$dest, (int_vp_gather_loadi v16i32:$ptr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADF : FormatCUnmaskedInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr),
	"vf$dest = mem_l[v$ptr]",
	[(set v16f32:$dest, (int_vp_gather_loadf v16i32:$ptr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"v$dest{{s$mask}} = mem_l[v$ptr]",
	[(set v16i32:$dest, (int_vp_gather_loadi_masked v16i32:$ptr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def INT_GATHER_LOADF_MASKED : FormatCMaskedInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"vf$dest{{s$mask}} = mem_l[v$ptr]",
	[(set v16f32:$dest, (int_vp_gather_loadf_masked v16i32:$ptr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def INT_BLOCK_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"v$dest{{s$mask}} = mem_l[s$ptr]",
	[(set v16i32:$dest, (int_vp_block_loadi_masked i32:$ptr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

def INT_BLOCK_LOADF_MASKED : FormatCMaskedInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"vf$dest{{s$mask}} = mem_l[s$ptr]",
	[(set v16f32:$dest, (int_vp_block_loadf_masked i32:$ptr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

let hasSideEffects = 1, mayStore = 1 in {
	def INT_SCATTER_STOREI : FormatCUnmaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value),
		"mem_l[v$ptr] = v$value",
		[(int_vp_scatter_storei v16i32:$ptr, v16i32:$value)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREF : FormatCUnmaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value),
		"mem_l[v$ptr] = v$value",
		[(int_vp_scatter_storef v16i32:$ptr, v16f32:$value)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[v$ptr]{{s$mask}} = v$value",
		[(int_vp_scatter_storei_masked v16i32:$ptr, v16i32:$value, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_SCATTER_STOREF_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[v$ptr]{{s$mask}} = v$value",
		[(int_vp_scatter_storef_masked v16i32:$ptr, v16f32:$value, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_BLOCK_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[s$ptr]{{s$mask}} = v$value",
		[(int_vp_block_storei_masked i32:$ptr, v16i32:$value, i32:$mask)],
		FmtC_BlockMasked,
		0>;

	def INT_BLOCK_STOREF_MASKED : FormatCMaskedInst<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$value, ScalarReg:$mask),
		"mem_l[s$ptr]{{s$mask}} = v$value",
		[(int_vp_block_storef_masked i32:$ptr, v16f32:$value, i32:$mask)],
		FmtC_BlockMasked,
		0>;
}

//////////////////////////////////////////////////////////////////
// Flow Control (format E)
//////////////////////////////////////////////////////////////////

let isBarrier = 1 in {
	def GOTO : BranchInst<
		(outs),
		(ins brtarget:$offset),
		"goto $offset",
		[(br bb:$offset)],
		BT_Uncond>;
}

def IFFALSE	: BranchInst<
	(outs), 
	(ins ScalarReg:$rs, brtarget:$offset),
	"if !s$rs goto $offset",
	[(brcond (i32 (seteq i32:$rs, 0)), bb:$offset)],
	BT_IfFalse> ;

def IFTRUE	: BranchInst<
	(outs), 
	(ins ScalarReg:$rs, brtarget:$offset),
	"if s$rs goto $offset",
	[(brcond i32:$rs, bb:$offset)],
	BT_IfTrue> ;

def return : SDNode<"SPISD::RET_FLAG", 
	SDTypeProfile<0, 0, []>,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [FP_REG] in {
	def RET : FormatAInst<
		(outs),
		(ins),
		"pc = link",
		[(return)],
		0x0f,
		FmtA_SSS>;
}

def SDT_SPCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_SPCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SPCallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_SPCallSeqEnd,
                           [SDNPHasChain, SDNPSideEffect, SDNPOptInGlue, SDNPOutGlue]>;

let Defs = [SP_REG], Uses = [SP_REG], hasSideEffects = 1 in {
	def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
								   "; ADJCALLSTACKDOWN $amt",
								   [(callseq_start timm:$amt)]>;
	def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
								"; ADJCALLSTACKUP $amt1",
								[(callseq_end timm:$amt1, timm:$amt2)]>;
}

def calltarget : Operand<i32>;
def SDT_SPCall : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;
def call       : SDNode<"SPISD::CALL", SDT_SPCall,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                            SDNPVariadic]>;

let isCall = 1, Defs = [S0, S1, S2, S3, S4, LINK_REG ] in {
	def CALL : BranchInst<
		(outs), 
		(ins calltarget:$dest, variable_ops),
		"call $dest", 
		[],
		BT_Call>;

	def JMPLri : BranchInst<
		(outs), 
		(ins MEMri:$ptr, variable_ops),
		"call $ptr",
		[(call ADDRri:$ptr)],
		BT_CallReg>;
}

def : Pat<(call tglobaladdr:$dest),
          (CALL tglobaladdr:$dest)>;
def : Pat<(call texternalsym:$dest),
          (CALL texternalsym:$dest)>;

// XXXX need pattern fragment for VMUX

// selcondresult is (dest, predicate, trueval, falseval)
def selcondresult : SDNode<"SPISD::SEL_COND_RESULT", SDTypeProfile<1, 3, [  
	SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>]>>;

// SELECT pseudo instructions
let usesCustomInserter = 1 in {
	def SELECTI : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		"; SELECTI Pseudo",
		[(set i32:$dest, (selcondresult i32:$pred, i32:$true, i32:$false))]>;

	def SELECTF : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		"; SELECTF Pseudo",
		[(set f32:$dest, (selcondresult i32:$pred, f32:$true, f32:$false))]>;

	def SELECTVI : Pseudo<
		(outs VectorReg:$dest),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		"; SELECTVI Pseudo",
		[(set v16i32:$dest, (selcondresult i32:$pred, v16i32:$true, v16i32:$false))]>;

	def SELECTVF : Pseudo<
		(outs VectorReg:$dest),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		"; SELECTVF Pseudo",
		[(set v16f32:$dest, (selcondresult i32:$pred, v16f32:$true, v16f32:$false))]>;
}

//////////////////////////////////////////////////////////////////
// Misc 
//////////////////////////////////////////////////////////////////

def GET_CURRENT_STRAND : FormatCUnmaskedInst<
	(outs ScalarReg:$dest),
	(ins),
	"s$dest = cr0",
	[(set i32:$dest, (int_vp_get_current_strand))],
	FmtC_ControlReg,
	1>;

// $expr will actually expand to "fp + <offset>"
def LOAD_FRAME_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins ComputeFrameAddr:$expr),
	"s$dest = $expr",
	[(set i32:$dest, ADDRri:$expr)]>;

// These use the literal pool feature of the current assembler.  That doesn't 
// exist with the integrated assembler, so this needs to be reimplemented within
// LLVM

// The assembler will turn this into a load from the literal pool if the
// size exceeds the instruction's immediate field.
def LOADIMM : FormatBInst<
	(outs ScalarReg:$dest),
	(ins i32imm:$val),
	"s$dest = $val",
	[(set i32:$dest, imm:$val)],
	0x0f,
	FmtB_SS>;

def LOAD_GLOBAL_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"s$dest = &$label",
	[(set i32:$dest, (LoadLiteral tglobaladdr:$label))]>;

// Address of object within constant pool (which right now will always be
// a vector constant, since those are the only objects we put in constant pool).
def LOAD_CPOOL_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"s$dest = &$label",
	[(set i32:$dest, (wrapper tconstpool:$label))]>;
