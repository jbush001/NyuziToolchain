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
defm RECIP  : VPFunctionalFloatArith<"reciprocal", reciprocal>;

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

// XXX need predicated versions of these
def SITOF : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
            "f$dst = itof(s$src)",
        	[(set f32:$dst, (sint_to_fp i32:$src))]>;

def SITOFV : VPInstruction<
			(outs VectorReg:$dst), 
			(ins VectorReg:$src),
            "vf$dst = itof(v$src)",
        	[(set v16f32:$dst, (sint_to_fp v16i32:$src))]>;

def FTOSI : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
        	"s$dst = ftoi(f$src)",
        	[(set i32:$dst, (fp_to_sint f32:$src))]>;

def FTOSIV : VPInstruction<
			(outs VectorReg:$dst), 
			(ins VectorReg:$src),
        	"v$dst = ftoi(vf$src)",
        	[(set v16i32:$dst, (fp_to_sint v16f32:$src))]>;

def MOVEREG : VPInstruction<
			(outs ScalarReg:$dst), 
			(ins ScalarReg:$src),
        	"s$dst = s$src",
        	[]>;

defm SGTSI : CMPI<">", "", SETGT, int_vp_mask_cmpi_sgt>;	
defm SGESI : CMPI<">=", "", SETGE, int_vp_mask_cmpi_sge>;
defm SLTSI : CMPI<"<", "", SETLT, int_vp_mask_cmpi_slt>;
defm SLESI : CMPI<"<=", "", SETLE, int_vp_mask_cmpi_sle>;
defm SEQSI : CMPI<"==", "", SETEQ, int_vp_mask_cmpi_eq>;
defm SNESI : CMPI<"<>", "", SETNE, int_vp_mask_cmpi_ne>;
defm SGTUI : CMPI<">", "u", SETUGT, int_vp_mask_cmpi_ugt>;	
defm SGEUI : CMPI<">=", "u", SETUGE, int_vp_mask_cmpi_uge>;
defm SLTUI : CMPI<"<", "u", SETULT, int_vp_mask_cmpi_ult>;
defm SLEUI : CMPI<"<=", "u", SETULE, int_vp_mask_cmpi_ule>;
defm SGTFO : CMPF<">", SETOGT, int_vp_mask_cmpf_gt>;	// Note: unordered and ordered treated the same
defm SGEFO : CMPF<">=", SETOGE, int_vp_mask_cmpf_ge>;
defm SLTFO : CMPF<"<", SETOLT, int_vp_mask_cmpf_lt>;
defm SLEFO : CMPF<"<=", SETOLE, int_vp_mask_cmpf_le>;
defm SEQFO : CMPF<"==", SETOEQ, int_vp_mask_cmpf_eq>;
defm SNEFO : CMPF<"<>", SETONE, int_vp_mask_cmpf_ne>;
defm SGTFU : CMPF<">", SETUGT, int_vp_mask_cmpf_gt>;
defm SGEFU : CMPF<">=", SETUGE, int_vp_mask_cmpf_ge>;
defm SLTFU : CMPF<"<", SETULT, int_vp_mask_cmpf_lt>;
defm SLEFU : CMPF<"<=", SETULE, int_vp_mask_cmpf_le>;
defm SEQFU : CMPF<"==", SETUEQ, int_vp_mask_cmpf_eq>;
defm SNEFU : CMPF<"<>", SETUNE, int_vp_mask_cmpf_ne>;

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

def GET_FIELDI : VPInstruction<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"s$dest = getfield(v$src, s$index)",
	[(set i32:$dest, (extractelt v16i32:$src, i32:$index))]>;

def GET_FIELDF : VPInstruction<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"f$dest = getfield(vf$src, s$index)",
	[(set f32:$dest, (extractelt v16f32:$src, i32:$index))]>;

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

def return : SDNode<"SPISD::RET_FLAG", 
	SDTypeProfile<0, 0, []>,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [FP_REG] in {
	def RET : VPInstruction<
		(outs),
		(ins),
		"pc = link",
		[(return)]>;
}

def SDT_SPCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_SPCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SPCallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_SPCallSeqEnd,
                           [SDNPHasChain, SDNPSideEffect, SDNPOptInGlue, SDNPOutGlue]>;

let Defs = [SP_REG], Uses = [SP_REG], hasSideEffects = 1 in {
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

let isCall = 1, Defs = [S0, S1, S2, S3, S4, LINK_REG ] in {
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

def LOAD_GLOBAL_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"s$dest = &$label",
	[(set i32:$dest, (LoadLiteral tglobaladdr:$label))]>;

def LOAD_FRAME_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins ComputeFrameAddr:$expr),
	"s$dest = $expr",
	[(set i32:$dest, ADDRri:$expr)]>;

def LOAD_CPOOL_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"s$dest = &$label",
	[(set i32:$dest, (wrapper tconstpool:$label))]>;

// Intrinsics
def GET_CURRENT_STRAND : VPInstruction<
	(outs ScalarReg:$dest),
	(ins),
	"s$dest = cr0",
	[(set i32:$dest, (int_vp_get_current_strand))]>;

def CLONE_SCALARI : VPInstruction<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"v$dest = s$src",
	[(set v16i32:$dest, (splat i32:$src))]>;

def CLONE_SCALARF : VPInstruction<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"vf$dest = f$src",
	[(set v16f32:$dest, (splat f32:$src))]>;

let Constraints = "$dest = $oldvalue" in {
	def INSERT_VECTORI : VPInstruction<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"v$dest{{s$mask}} = s$newLane",
		[(set v16i32:$dest, (vselect i32:$mask, (splat i32:$newLane), v16i32:$oldvalue))]>;

	def INSERT_VECTORF : VPInstruction<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"vf$dest{{s$mask}} = f$newLane",
		[(set v16f32:$dest, (vselect i32:$mask, (splat f32:$newLane), v16f32:$oldvalue))]>;
}	

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

// selcondresult is (dest, predicate, trueval, falseval)
def selcondresult : SDNode<"SPISD::SEL_COND_RESULT", SDTypeProfile<1, 3, [  
	SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>]>>;

// SELECT pseudo instructions
let usesCustomInserter = 1 in {
	def SELECTI : Pseudo<
		(outs ScalarReg:$dst),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		"; SELECTI Pseudo",
		[(set i32:$dst, (selcondresult i32:$pred, i32:$true, i32:$false))]>;

	def SELECTF : Pseudo<
		(outs ScalarReg:$dst),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		"; SELECTF Pseudo",
		[(set f32:$dst, (selcondresult i32:$pred, f32:$true, f32:$false))]>;

	def SELECTVI : Pseudo<
		(outs VectorReg:$dst),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		"; SELECTVI Pseudo",
		[(set v16i32:$dst, (selcondresult i32:$pred, v16i32:$true, v16i32:$false))]>;

	def SELECTVF : Pseudo<
		(outs VectorReg:$dst),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		"; SELECTVF Pseudo",
		[(set v16f32:$dst, (selcondresult i32:$pred, v16f32:$true, v16f32:$false))]>;
}
