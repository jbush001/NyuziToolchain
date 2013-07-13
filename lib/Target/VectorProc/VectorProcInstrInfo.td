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

defm AND    : TwoOpIntArith<"and", and, 0x01>;
defm OR     : TwoOpIntArith<"or", or, 0x00>;
defm XOR    : TwoOpIntArith<"xor", xor, 0x03>;
defm SLL    : TwoOpIntArith<"shl", shl, 0x0b>;
defm SRL    : TwoOpIntArith<"shr", srl, 0x0a>;
defm SRA    : TwoOpIntArith<"ashr", sra, 0x09>;	
defm ADDI   : TwoOpIntArith<"add.i", add, 0x05>;
defm SUBI   : TwoOpIntArith<"sub.i", sub, 0x06>;
defm SMULI  : TwoOpIntArith  <"mul.i", mul, 0x07>;
defm ADDF   : TwoOpFloatArith<"add.f", fadd, 0x20>;
defm SUBF   : TwoOpFloatArith<"sub.f", fsub, 0x21>;
defm MULF   : TwoOpFloatArith<"mul.f", fmul, 0x22>;
defm CLZ 	: OneOpIntArith<"clz", ctlz, 0x0c>;
defm CTZ 	: OneOpIntArith<"ctz", cttz, 0x0e>;
defm CLZ_ZU	: OneOpIntArith<"clz", ctlz_zero_undef, 0x0c>;
defm CTZ_ZU	: OneOpIntArith<"ctz", cttz_zero_undef, 0x0e>;
defm RECIP  : OneOpFloatArith<"reciprocal", reciprocal, 0x1c>;

def SEXT16 : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src),
		"sext.16 $dest, $src",
		[(set ScalarReg:$dest, (sext_inreg i32:$src, i16))],
		0x1e,
		FmtA_SSS>;

def SEXT8 : FormatAInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src),
		"sext.8 $dest, $src",
		[(set ScalarReg:$dest, (sext_inreg i32:$src, i8))],
		0x1d,
		FmtA_SSS>;

// XXX need predicated versions of these
def SITOF : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
            "itof $dest, $src",
        	[(set f32:$dest, (sint_to_fp i32:$src))],
        	0x2a,
        	FmtA_SSS>;

def SITOFV : FormatAInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src),
            "itof $dest, $src",
        	[(set v16f32:$dest, (sint_to_fp v16i32:$src))],
        	0x2a,
        	FmtA_VVV>;

def FTOSI : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
        	"ftoi $dest, $src",
        	[(set i32:$dest, (fp_to_sint f32:$src))],
        	0x1b,
        	FmtA_SSS>;

def FTOSIV : FormatAInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src),
        	"ftoi $dest, $src",
        	[(set v16i32:$dest, (fp_to_sint v16f32:$src))],
        	0x1b,
        	FmtA_VVV>;

def MOVEREG : FormatAInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src),
        	"move $dest, $src",
        	[],
        	0x0f,
        	FmtA_SSS>;

defm SGTSI : IntCompareInst<"setgt", "i", SETGT, int_vp_mask_cmpi_sgt, 0x12>;	
defm SGESI : IntCompareInst<"setge", "i", SETGE, int_vp_mask_cmpi_sge, 0x13>;
defm SLTSI : IntCompareInst<"setlt", "i", SETLT, int_vp_mask_cmpi_slt, 0x14>;
defm SLESI : IntCompareInst<"setle", "i", SETLE, int_vp_mask_cmpi_sle, 0x15>;
defm SEQSI : IntCompareInst<"seteq", "i", SETEQ, int_vp_mask_cmpi_eq, 0x10>;
defm SNESI : IntCompareInst<"setne", "i", SETNE, int_vp_mask_cmpi_ne, 0x11>;
defm SGTUI : IntCompareInst<"setgt", "u", SETUGT, int_vp_mask_cmpi_ugt, 0x16>;	
defm SGEUI : IntCompareInst<"setge", "u", SETUGE, int_vp_mask_cmpi_uge, 0x17>;
defm SLTUI : IntCompareInst<"setlt", "u", SETULT, int_vp_mask_cmpi_ult, 0x18>;
defm SLEUI : IntCompareInst<"setle", "u", SETULE, int_vp_mask_cmpi_ule, 0x19>;

// Note: unordered and ordered treated the same
defm SGTFO : FloatCompareInst<"setgt", SETOGT, int_vp_mask_cmpf_gt, 0x2c>;	
defm SGEFO : FloatCompareInst<"setge", SETOGE, int_vp_mask_cmpf_ge, 0x2d>;
defm SLTFO : FloatCompareInst<"setlt", SETOLT, int_vp_mask_cmpf_lt, 0x2e>;
defm SLEFO : FloatCompareInst<"setle", SETOLE, int_vp_mask_cmpf_le, 0x2f>;
defm SEQFO : FloatCompareInst<"seteq", SETOEQ, int_vp_mask_cmpf_eq, 0x10>;
defm SNEFO : FloatCompareInst<"setne", SETONE, int_vp_mask_cmpf_ne, 0x11>;
defm SGTFU : FloatCompareInst<"setgt", SETUGT, int_vp_mask_cmpf_gt, 0x2c>;
defm SGEFU : FloatCompareInst<"setge", SETUGE, int_vp_mask_cmpf_ge, 0x2d>;
defm SLTFU : FloatCompareInst<"setlt", SETULT, int_vp_mask_cmpf_lt, 0x2e>;
defm SLEFU : FloatCompareInst<"setle", SETULE, int_vp_mask_cmpf_le, 0x2f>;
defm SEQFU : FloatCompareInst<"seteq", SETUEQ, int_vp_mask_cmpf_eq, 0x10>;
defm SNEFU : FloatCompareInst<"setne", SETUNE, int_vp_mask_cmpf_ne, 0x11>;

def GET_FIELDI : FormatAInst<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"getfield $dest, $src, $index",
	[(set i32:$dest, (extractelt v16i32:$src, i32:$index))],
	0x1a,
	FmtA_VVV>;

def GET_FIELDF : FormatAInst<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src, ScalarReg:$index),
	"getfield $dest, $src, $index",
	[(set f32:$dest, (extractelt v16f32:$src, i32:$index))],
	0x1a,
	FmtA_VVV>;

def SHUFFLE : FormatAInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$src, VectorReg:$indices),
	"shuffle $dest, $src, $indices",
	[(set v16i32:$dest, (vector_shuffle v16i32:$src, v16i32:$indices))],
	0x0d,
	FmtA_VVV>;

def CLONE_SCALARI : FormatAInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"move $dest, $src",
	[(set v16i32:$dest, (splat i32:$src))],
	0x0f,
	FmtA_VVS>;

def CLONE_SCALARF : FormatAInst<
	(outs VectorReg:$dest),
	(ins ScalarReg:$src),
	"move $dest, $src",
	[(set v16f32:$dest, (splat f32:$src))],
	0x0f,
	FmtA_VVS>;

let Constraints = "$dest = $oldvalue" in {
	def INSERT_VECTORI : FormatAInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"move $dest {{ $mask }}, $newLane",
		[(set v16i32:$dest, (vselect i32:$mask, (splat i32:$newLane), v16i32:$oldvalue))],
		0x0f,
		FmtA_VVS>;

	def INSERT_VECTORF : FormatAInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$newLane, VectorReg:$oldvalue),
		"move $dest {{ $mask }}, $newLane",
		[(set v16f32:$dest, (vselect i32:$mask, (splat f32:$newLane), v16f32:$oldvalue))],
		0x0f,
		FmtA_VVS>;
}

//////////////////////////////////////////////////////////////////
// Memory Access (Format C)
//////////////////////////////////////////////////////////////////

// Scalar
defm LBS : ScalarLoadInst<"s8", sextloadi8, FmtC_Byte_Signed>;
defm LBU : ScalarLoadInst<"u8", zextloadi8, FmtC_Byte_Unsigned>;
defm LSS : ScalarLoadInst<"s16", sextloadi16, FmtC_Short_Signed>;
defm LSU : ScalarLoadInst<"u16", zextloadi16, FmtC_Short_Unsigned>;
defm LW : ScalarLoadInst<"32", load, FmtC_Word>;
defm SB : ScalarStoreInst<"8", truncstorei8, FmtC_Byte_Signed>;
defm SS : ScalarStoreInst<"16", truncstorei16, FmtC_Short_Signed>;
defm SW : ScalarStoreInst<"32", store, FmtC_Word>;

// A bit of a kludge.  Used to store the result of a vector comparison. 
// The compiler does this in some cases and the normal store does not match it.
def STORE_MASK : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$ptr, ScalarReg:$srcDest),
	"store.v $srcDest, $ptr",
	[(store v16i1:$srcDest, ADDRri:$ptr)],
	FmtC_Word,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSSi ADDRri:$src)>;

// Vector
def BLOCK_STOREI : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$ptr, VectorReg:$srcDest),
	"store.v $srcDest, $ptr",
	[(store v16i32:$srcDest, ADDRri:$ptr)],
	FmtC_Block,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_STOREF : FormatCUnmaskedInst<
	(outs),
	(ins MEMri:$ptr, VectorReg:$srcDest),
	"store.v $srcDest, $ptr",
	[(store v16f32:$srcDest, ADDRri:$ptr)],
	FmtC_Block,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def BLOCK_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins MEMri:$ptr),
	"load.v $srcDest, $ptr",
	[(set v16i32:$srcDest, (load ADDRri:$ptr))],
	FmtC_Block,
	1>;

def BLOCK_LOADF : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins MEMri:$ptr),
	"load.v $srcDest, $ptr",
	[(set v16f32:$srcDest, (load ADDRri:$ptr))],
	FmtC_Block,
	1>;

def INT_GATHER_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins VectorReg:$ptr),
	"load.v $srcDest, ( $ptr )",
	[(set v16i32:$srcDest, (int_vp_gather_loadi v16i32:$ptr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADF : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins VectorReg:$ptr),
	"load.v $srcDest, ( $ptr )",
	[(set v16f32:$srcDest, (int_vp_gather_loadf v16i32:$ptr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"load.v $srcDest {{ $mask }}, ( $ptr )",
	[(set v16i32:$srcDest, (int_vp_gather_loadi_masked v16i32:$ptr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def INT_GATHER_LOADF_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins VectorReg:$ptr, ScalarReg:$mask),
	"load.v $srcDest {{ $mask }}, ( $ptr )",
	[(set v16f32:$srcDest, (int_vp_gather_loadf_masked v16i32:$ptr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def INT_BLOCK_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"load.v $srcDest {{ $mask }}, ( $ptr )",
	[(set v16i32:$srcDest, (int_vp_block_loadi_masked i32:$ptr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

def INT_BLOCK_LOADF_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins ScalarReg:$ptr, ScalarReg:$mask),
	"load.v $srcDest {{ $mask }}, ( $ptr )",
	[(set v16f32:$srcDest, (int_vp_block_loadf_masked i32:$ptr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

let hasSideEffects = 1, mayStore = 1 in {
	def INT_SCATTER_STOREI : FormatCUnmaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$srcDest),
		"store.v $srcDest, ( $ptr )",
		[(int_vp_scatter_storei v16i32:$ptr, v16i32:$srcDest)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREF : FormatCUnmaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$srcDest),
		"store.v $srcDest, ( $ptr )",
		[(int_vp_scatter_storef v16i32:$ptr, v16f32:$srcDest)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$srcDest, ScalarReg:$mask),
		"store.v $srcDest {{ $mask }}, ( $ptr )",
		[(int_vp_scatter_storei_masked v16i32:$ptr, v16i32:$srcDest, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_SCATTER_STOREF_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$ptr, VectorReg:$srcDest, ScalarReg:$mask),
		"store.v $srcDest {{ $mask }}, ( $ptr )",
		[(int_vp_scatter_storef_masked v16i32:$ptr, v16f32:$srcDest, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_BLOCK_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$srcDest, ScalarReg:$mask),
		"store.v $srcDest {{ $mask }}, ( $ptr )",
		[(int_vp_block_storei_masked i32:$ptr, v16i32:$srcDest, i32:$mask)],
		FmtC_BlockMasked,
		0>;

	def INT_BLOCK_STOREF_MASKED : FormatCMaskedInst<
		(outs),
		(ins ScalarReg:$ptr, VectorReg:$srcDest, ScalarReg:$mask),
		"store.v $srcDest {{ $mask }}, ( $ptr )",
		[(int_vp_block_storef_masked i32:$ptr, v16f32:$srcDest, i32:$mask)],
		FmtC_BlockMasked,
		0>;
}

//////////////////////////////////////////////////////////////////
// Flow Control (format E)
//////////////////////////////////////////////////////////////////

let isBarrier = 1 in {
	def GOTO : UnconditionalBranchInst<
		(outs),
		(ins brtarget:$offset),
		"goto $offset",
		[(br bb:$offset)],
		BT_Uncond>;
}

def IFFALSE	: ConditionalBranchInst<
	(outs), 
	(ins ScalarReg:$test, brtarget:$dest),
	"bfalse $test, $dest",
	[(brcond (i32 (seteq i32:$test, 0)), bb:$dest)],
	BT_IfFalse> ;

def IFTRUE	: ConditionalBranchInst<
	(outs), 
	(ins ScalarReg:$test, brtarget:$dest),
	"btrue $test, $dest",
	[(brcond i32:$test, bb:$dest)],
	BT_IfTrue> ;

def return : SDNode<"VectorProcISD::RET_FLAG", 
	SDTypeProfile<0, 0, []>,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

let isReturn = 1, isTerminator = 1, isBarrier = 1, Uses = [FP_REG] in {
	def RET : VPInstruction<
		(outs),
		(ins),
		"move pc, link",
		[(return)]>
	{
		let Inst{31-29} = 6;	// format A instruction
		let Inst{25-20} = 0xf;	// opcode
		let Inst{9-5} = 31;		// dest (reg 31)
		let Inst{4-0} = 30;		// src (link)
	}
}

let Defs = [SP_REG], Uses = [SP_REG], hasSideEffects = 1 in {
	def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
								   " ; ADJCALLSTACKDOWN",
								   [(callseq_start timm:$amt)]>;
	def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
								" ; ADJCALLSTACKUP",
								[(callseq_end timm:$amt1, timm:$amt2)]>;
}

let isCall = 1, Defs = [S0, S1, S2, S3, S4, LINK_REG ] in {
	def CALL : UnconditionalBranchInst<
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
		BT_CallReg>
	{
		// XXX this instruction will probably assert because there is no $dest
		
		bits<5> ptr;

		let Inst{4-0} = ptr;
	}
}

def : Pat<(call tglobaladdr:$dest),
          (CALL tglobaladdr:$dest)>;
def : Pat<(call texternalsym:$dest),
          (CALL texternalsym:$dest)>;

// XXXX need pattern fragment for VMUX

// selcondresult is (dest, predicate, trueval, falseval)
def selcondresult : SDNode<"VectorProcISD::SEL_COND_RESULT", SDTypeProfile<1, 3, [  
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

def GET_CURRENT_STRAND : FormatCInst<
	(outs ScalarReg:$dest),
	(ins),
	"loadcr $dest, 0",
	[(set i32:$dest, (int_vp_get_current_strand))],
	FmtC_ControlReg,
	1>;

// $expr will actually expand to "fp + <offset>"
def LOAD_FRAME_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins MEMri:$expr),
	"add.i $dest, $expr",
	[(set i32:$dest, ADDRri:$expr)]>;

def LOAD_CPOOLI : VPInstruction<
	(outs ScalarReg:$dest),
	(ins Operand<iPTR>:$label),
	"load.32 $dest, $label",
	[(set i32:$dest, (load tconstpool:$label))]>;

// This should only be invoked for types that will fit in the immediate field 
// of the instruction.  The lowering code will transform other types into
// constant pool loads.
def LOADIMM : FormatBInst<
	(outs ScalarReg:$dest),
	(ins i32imm:$val),
	"move $dest, $val",
	[(set i32:$dest, imm:$val)],
	0x0f,
	FmtB_SS>;

