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
defm RECIP  : OneOpFloatArith<"reciprocal", reciprocal, 0x1c>;

def SEXT16 : FormatAUnmaskedOneOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src2),
		"sext.16 $dest, $src2",
		[(set ScalarReg:$dest, (sext_inreg i32:$src2, i16))],
		0x1e,
		FmtA_SSS>;

def SEXT8 : FormatAUnmaskedOneOpInst<
		(outs ScalarReg:$dest), 
		(ins ScalarReg:$src2),
		"sext.8 $dest, $src2",
		[(set ScalarReg:$dest, (sext_inreg i32:$src2, i8))],
		0x1d,
		FmtA_SSS>;

// XXX need predicated versions of these
def SITOF : FormatAUnmaskedOneOpInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src2),
            "itof $dest, $src2",
        	[(set f32:$dest, (sint_to_fp i32:$src2))],
        	0x2a,
        	FmtA_SSS>;

def SITOFV : FormatAUnmaskedOneOpInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src2),
            "itof $dest, $src2",
        	[(set v16f32:$dest, (sint_to_fp v16i32:$src2))],
        	0x2a,
        	FmtA_VVV>;

def FTOSI : FormatAUnmaskedOneOpInst<
			(outs ScalarReg:$dest), 
			(ins ScalarReg:$src2),
        	"ftoi $dest, $src2",
        	[(set i32:$dest, (fp_to_sint f32:$src2))],
        	0x1b,
        	FmtA_SSS>;

def FTOSIV : FormatAUnmaskedOneOpInst<
			(outs VectorReg:$dest), 
			(ins VectorReg:$src2),
        	"ftoi $dest, $src2",
        	[(set v16i32:$dest, (fp_to_sint v16f32:$src2))],
        	0x1b,
        	FmtA_VVV>;

defm SGTSI : IntCompareInst<"setgt", "i", SETGT, 0x12>;	
defm SGESI : IntCompareInst<"setge", "i", SETGE, 0x13>;
defm SLTSI : IntCompareInst<"setlt", "i", SETLT, 0x14>;
defm SLESI : IntCompareInst<"setle", "i", SETLE, 0x15>;
defm SEQSI : IntCompareInst<"seteq", "i", SETEQ, 0x10>;
defm SNESI : IntCompareInst<"setne", "i", SETNE, 0x11>;
defm SGTUI : IntCompareInst<"setgt", "u", SETUGT, 0x16>;	
defm SGEUI : IntCompareInst<"setge", "u", SETUGE, 0x17>;
defm SLTUI : IntCompareInst<"setlt", "u", SETULT, 0x18>;
defm SLEUI : IntCompareInst<"setle", "u", SETULE, 0x19>;

// Intrinsic forms of compare instructions.  This is a bit of a hack,
// since I can't match the instruction forms in a way that works properly
// with the type legalizer.
def : Pat<(int_vp_mask_cmpi_sgt v16i32:$src1, v16i32:$src2),
	(SGTSIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_sgt v16i32:$src1, (splat i32:$src2)),
	(SGTSIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_sge v16i32:$src1, v16i32:$src2),
	(SGESIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_sge v16i32:$src1, (splat i32:$src2)),
	(SGESIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_slt v16i32:$src1, v16i32:$src2),
	(SLTSIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_slt v16i32:$src1, (splat i32:$src2)),
	(SLTSIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_sle v16i32:$src1, v16i32:$src2),
	(SLESIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_sle v16i32:$src1, (splat i32:$src2)),
	(SLESIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_eq v16i32:$src1, v16i32:$src2),
	(SEQSIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_eq v16i32:$src1, (splat i32:$src2)),
	(SEQSIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ne v16i32:$src1, v16i32:$src2),
	(SNESIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ne v16i32:$src1, (splat i32:$src2)),
	(SNESIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ugt v16i32:$src1, v16i32:$src2),
	(SGTUIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ugt v16i32:$src1, (splat i32:$src2)),
	(SGTUIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_uge v16i32:$src1, v16i32:$src2),
	(SGEUIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_uge v16i32:$src1, (splat i32:$src2)),
	(SGEUIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ult v16i32:$src1, v16i32:$src2),
	(SLTUIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ult v16i32:$src1, (splat i32:$src2)),
	(SLTUIVVS v16i32:$src1, i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ule v16i32:$src1, v16i32:$src2),
	(SLEUIVVV v16i32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_mask_cmpi_ule v16i32:$src1, (splat i32:$src2)),
	(SLEUIVVS v16i32:$src1, i32:$src2)>;

defm SGTFO : FloatCompareInst<"setgt", SETOGT, 0x2c>;	
defm SGEFO : FloatCompareInst<"setge", SETOGE, 0x2d>;
defm SLTFO : FloatCompareInst<"setlt", SETOLT, 0x2e>;
defm SLEFO : FloatCompareInst<"setle", SETOLE, 0x2f>;

// Intrinsic forms of compare instructions.  This is a bit of a hack,
// since I can't match the instruction forms in a way that works properly
// with the type legalizer.
def : Pat<(int_vp_mask_cmpf_gt v16f32:$src1, v16f32:$src2),
	(SGTFOVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_gt v16f32:$src1, (splat f32:$src2)),
	(SGTFOVVS  v16f32:$src1, f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ge v16f32:$src1, v16f32:$src2),
	(SGEFOVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ge v16f32:$src1, (splat f32:$src2)),
	(SGEFOVVS  v16f32:$src1, f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_lt v16f32:$src1, v16f32:$src2),
	(SLTFOVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_lt v16f32:$src1, (splat f32:$src2)),
	(SLTFOVVS  v16f32:$src1, f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_le v16f32:$src1, v16f32:$src2),
	(SLEFOVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_le v16f32:$src1, (splat f32:$src2)),
	(SLEFOVVS  v16f32:$src1, f32:$src2)>;
	
// Note: there is no floating point eq/ne.  Just use integer
// forms
def : Pat<(int_vp_mask_cmpf_eq v16f32:$src1, v16f32:$src2),
	(SEQSIVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_eq v16f32:$src1, (splat f32:$src2)),
	(SEQSIVVS  v16f32:$src1, f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ne v16f32:$src1, v16f32:$src2),
	(SNESIVVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ne v16f32:$src1, (splat f32:$src2)),
	(SNESIVVS  v16f32:$src1, f32:$src2)>;

def GET_FIELDI : FormatAUnmaskedTwoOpInst<
	(outs ScalarReg:$dest),
	(ins VectorReg:$src1, ScalarReg:$src2),
	"getfield $dest, $src1, $src2",
	[(set i32:$dest, (getfield v16i32:$src1, i32:$src2))],
	0x1a,
	FmtA_VVS>;

def : Pat<(getfield v16f32:$src1, i32:$src2),
	(GET_FIELDI v16f32:$src1, i32:$src2)>; 

def SHUFFLEI : FormatAUnmaskedTwoOpInst<
	(outs VectorReg:$dest),
	(ins VectorReg:$src1, VectorReg:$src2),
	"shuffle $dest, $src1, $src2",
	[(set v16i32:$dest, (vector_shuffle v16i32:$src1, v16i32:$src2))],
	0x0d,
	FmtA_VVV>;


def MOVESS : FormatAUnmaskedOneOpInst<
	(outs ScalarReg:$dest), 
	(ins ScalarReg:$src2),
	"move $dest, $src2",
	[],
	0xf,
	FmtA_SSS>;

def MOVEVSI : FormatAUnmaskedOneOpInst<
	(outs VectorReg:$dest), 
	(ins ScalarReg:$src2),
	"move $dest, $src2",
	[(set v16i32:$dest, (splat i32:$src2))],
	0xf,
	FmtA_VVS>;
	
def : Pat<(v16f32 (splat f32:$src2)), (MOVEVSI f32:$src2)>;

def MOVEVV : FormatAUnmaskedOneOpInst<
	(outs VectorReg:$dest), 
	(ins VectorReg:$src2),
	"move $dest, $src2",
	[],
	0xf,
	FmtA_VVV>;

// Predicated
let Constraints = "$dest = $oldvalue" in {
	def MOVEVVMI : FormatAMaskedOneOpInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, VectorReg:$src2, VectorReg:$oldvalue),
		"move.mask $dest, $mask, $src2",
		[(set v16i32:$dest, (vselect i32:$mask, v16i32:$src2, v16i32:$oldvalue))],
		0xf,
		FmtA_VVVM>;

	def MOVEVSMI : FormatAMaskedOneOpInst<
		(outs VectorReg:$dest),
		(ins ScalarReg:$mask, ScalarReg:$src2, VectorReg:$oldvalue),
		"move.mask $dest, $mask, $src2",
		[(set v16i32:$dest, (vselect i32:$mask, (splat i32:$src2), v16i32:$oldvalue))],
		0xf,
		FmtA_VVSM>;
}

def : Pat<(vselect i32:$mask, v16f32:$src2, v16f32:$oldvalue), 
	(MOVEVVMI i32:$mask, v16f32:$src2, v16f32:$oldvalue)>;
def : Pat<(vselect i32:$mask, (splat f32:$src2), v16f32:$oldvalue),
	(MOVEVSMI i32:$mask, f32:$src2, v16f32:$oldvalue)>; 

//////////////////////////////////////////////////////////////////
// Memory Access (Format C)
//////////////////////////////////////////////////////////////////

// Scalar
def LBS : ScalarLoadInst<"s8", sextloadi8, FmtC_Byte_Signed>;
def LBU : ScalarLoadInst<"u8", zextloadi8, FmtC_Byte_Unsigned>;
def LSS : ScalarLoadInst<"s16", sextloadi16, FmtC_Short_Signed>;
def LSU : ScalarLoadInst<"u16", zextloadi16, FmtC_Short_Unsigned>;
def LW : ScalarLoadInst<"32", load, FmtC_Word>;
def SB : ScalarStoreInst<"8", truncstorei8, FmtC_Byte_Signed>;
def SS : ScalarStoreInst<"16", truncstorei16, FmtC_Short_Signed>;
def SW : ScalarStoreInst<"32", store, FmtC_Word>;

// A bit of a kludge.  Used to store the result of a vector comparison. 
// The compiler does this in some cases and the normal store does not match it.
def : Pat<(store v16i1:$srcDest, ADDRri:$ptr),
	(SW v16i1:$srcDest, ADDRri:$ptr)>;

def : Pat<(i32 (extloadi1 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi8 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi16 ADDRri:$addr)), (LSS ADDRri:$addr)>;
def : Pat<(f32 (load ADDRri:$addr)), (LW ADDRri:$addr)>;
def : Pat<(store f32:$srcDest, ADDRri:$addr), (SW f32:$srcDest, ADDRri:$addr)>;

// Vector
def BLOCK_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins MEMri:$addr),
	"load.v $srcDest, $addr",
	[(set v16i32:$srcDest, (load ADDRri:$addr))],
	FmtC_Block,
	1>;

def BLOCK_STOREI : FormatCUnmaskedInst<
	(outs),
	(ins VectorReg:$srcDest, MEMri:$addr),
	"store.v $srcDest, $addr",
	[(store v16i32:$srcDest, ADDRri:$addr)],
	FmtC_Block,
	0>
{
	let hasSideEffects = 1;
	let mayStore = 1;
}

def : Pat<(v16f32 (load ADDRri:$addr)), (BLOCK_LOADI ADDRri:$addr)>;
def : Pat<(store v16f32:$srcDest, ADDRri:$addr), (BLOCK_STOREI v16f32:$srcDest, ADDRri:$addr)>;

def INT_BLOCK_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins MEMri:$addr, ScalarReg:$mask),
	"load.v.mask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_block_loadi_masked ADDRri:$addr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

def : Pat<(int_vp_block_loadf_masked ADDRri:$addr, i32:$mask),
	(INT_BLOCK_LOADI_MASKED ADDRri:$addr, i32:$mask)>;

def INT_GATHER_LOADI : FormatCUnmaskedInst<
	(outs VectorReg:$srcDest),
	(ins VMEMri:$addr),
	"load.gath $srcDest, $addr",
	[(set v16i32:$srcDest, (int_vp_gather_loadi VADDRri:$addr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADI_MASKED : FormatCMaskedInst<
	(outs VectorReg:$srcDest),
	(ins VMEMri:$addr, ScalarReg:$mask),
	"load.gath.mask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_gather_loadi_masked VADDRri:$addr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def : Pat<(int_vp_gather_loadf VADDRri:$addr), (INT_GATHER_LOADI VADDRri:$addr)>;
def : Pat<(int_vp_gather_loadf_masked VADDRri:$addr, i32:$mask),
	(INT_GATHER_LOADI_MASKED VADDRri:$addr, i32:$mask)>;

let hasSideEffects = 1, mayStore = 1 in {
	def INT_SCATTER_STOREI : FormatCUnmaskedInst<
		(outs),
		(ins VectorReg:$srcDest, VMEMri:$addr),
		"store.scat $srcDest, $addr",
		[(int_vp_scatter_storei VADDRri:$addr, v16i32:$srcDest)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$srcDest, VMEMri:$addr, ScalarReg:$mask),
		"store.scat.mask $srcDest, $mask, $addr",
		[(int_vp_scatter_storei_masked VADDRri:$addr, v16i32:$srcDest, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_BLOCK_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VectorReg:$srcDest, MEMri:$addr, ScalarReg:$mask),
		"store.v.mask $srcDest, $mask, $addr",
		[(int_vp_block_storei_masked ADDRri:$addr, v16i32:$srcDest, i32:$mask)],
		FmtC_BlockMasked,
		0>;
}

def : Pat<(int_vp_scatter_storef VADDRri:$addr, v16f32:$srcDest),
	(INT_SCATTER_STOREI v16f32:$srcDest, VADDRri:$addr)>;
def : Pat<(int_vp_scatter_storef_masked VADDRri:$addr, v16f32:$srcDest, i32:$mask),
	(INT_SCATTER_STOREI_MASKED v16f32:$srcDest, VADDRri:$addr, i32:$mask)>;
def : Pat<(int_vp_block_storef_masked ADDRri:$addr, v16f32:$srcDest, i32:$mask),
	(INT_BLOCK_STOREI_MASKED v16f32:$srcDest, ADDRri:$addr, i32:$mask)>;


def LOAD_SYNC : FormatCUnmaskedInst<
	(outs ScalarReg:$srcDest),
	(ins MEMri:$addr),
	"load.sync $srcDest, $addr",
	[],
	FmtC_Sync,
	1>;

def STORE_SYNC : FormatCUnmaskedInst<
	(outs ScalarReg:$result),
	(ins ScalarReg:$srcDest, MEMri:$addr),
	"store.sync $srcDest, $addr	",
	[],
	FmtC_Sync,
	0>
{
	let Constraints = "$result = $srcDest";
}

// Atomics	
let usesCustomInserter = 1 in {
	def ATOMIC_LOAD_ADD : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$amt),
		[(set i32:$dest, (atomic_load_add ScalarReg:$ptr, ScalarReg:$amt))]>;

	def ATOMIC_LOAD_SUB : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$amt),
		[(set i32:$dest, (atomic_load_sub ScalarReg:$ptr, ScalarReg:$amt))]>;

	def ATOMIC_LOAD_AND : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$amt),
		[(set i32:$dest, (atomic_load_and ScalarReg:$ptr, ScalarReg:$amt))]>;

	def ATOMIC_LOAD_OR : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$amt),
		[(set i32:$dest, (atomic_load_or ScalarReg:$ptr, ScalarReg:$amt))]>;

	def ATOMIC_LOAD_XOR : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$amt),
		[(set i32:$dest, (atomic_load_xor ScalarReg:$ptr, ScalarReg:$amt))]>;

	def ATOMIC_CMP_SWAP : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$ptr, ScalarReg:$cmp, ScalarReg:$swap),
		[(set i32:$dest, (atomic_cmp_swap ScalarReg:$ptr, ScalarReg:$cmp, 
			ScalarReg:$swap))]>;
}	

//////////////////////////////////////////////////////////////////
// Flow Control (format E)
//////////////////////////////////////////////////////////////////

let isTerminator = 1 in {
	def GOTO : UnconditionalBranchInst<
		(outs),
		(ins brtarget:$dest),
		"goto $dest",
		[(br bb:$dest)],
		BT_Uncond>
	{
		let isBarrier = 1;
	}

	def BFALSE : ConditionalBranchInst<
		(outs), 
		(ins ScalarReg:$test, brtarget:$dest),
		"bfalse $test, $dest",
		[(brcond (i32 (seteq i32:$test, 0)), bb:$dest)],
		BT_IfFalse>;

	def BTRUE : ConditionalBranchInst<
		(outs), 
		(ins ScalarReg:$test, brtarget:$dest),
		"btrue $test, $dest",
		[(brcond i32:$test, bb:$dest)],
		BT_IfTrue>;

	// Converts to MOVE pc, <srcreg>
	def JUMPREG : VPInstruction<
		(outs), 
		(ins ScalarReg:$dest),
		"goto $dest",
		[(brind i32:$dest)]>
	{
		bits<5> dest;

		let Inst{31-30} = 3;
		let Inst{25-20} = 0xf;	// opcode: move
		let Inst{9-5} = 31;
		let Inst{4-0} = dest;

		let isBranch = 1;
		let isIndirectBranch = 1;
		let isBarrier = 1;
	}

	// This loads the destination from the jump table directly into PC,
	// branching as a side effect.
	// $jumptable is not a real instruction operand. The AsmPrinter
	// will use it to output the jump table in-line.
	def JUMP_TABLE : VPInstruction<
		(outs), 
		(ins ScalarReg:$tableptr, ScalarReg:$jt),
		"load.32 pc, ( $tableptr )",
		[(BRjt i32:$tableptr, tjumptable:$jt)]>
	{
		let isBranch = 1;
		let isIndirectBranch = 1;
		let isBarrier = 1;

		bits<5> tableptr;

		let Inst{31} = 1;
		let Inst{29} = 1;		// Is load
		let Inst{28-25} = 4;	// Scalar, 32-bit
		let Inst{9-5} = 31;		// PC is destination
		let Inst{4-0} = tableptr;	// Register holds computed pointer into table
	}
}

def return : SDNode<"VectorProcISD::RET_FLAG", 
	SDTypeProfile<0, 0, []>,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def RET : VPInstruction<
	(outs),
	(ins),
	"ret",
	[(return)]>
{
	// This is encoded as move pc, link
	let Inst{31-29} = 6;	// format A instruction
	let Inst{25-20} = 0xf;	// opcode
	let Inst{9-5} = 31;		// dest (reg 31)
	let Inst{19-15} = 30;	// src (link)
	
	let isReturn = 1;
	let isTerminator = 1;
	let isBarrier = 1;
	let Uses = [FP_REG];
}

let Defs = [SP_REG], Uses = [SP_REG], hasSideEffects = 1 in {
	def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
								   [(callseq_start timm:$amt)]>;
	def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
								[(callseq_end timm:$amt1, timm:$amt2)]>;
}

// Note: Unlike other branches, call is not a terminator: it does not end a 
// basic block.
let isCall = 1, Defs = [S0, S1, S2, S3, S4, LINK_REG ] in {
	def CALLSYM : UnconditionalBranchInst<
		(outs), 
		(ins calltarget:$dest, variable_ops),
		"call $dest", 
		[],
		BT_Call>;

	def CALLREG : UnconditionalBranchInst<
		(outs), 
		(ins ScalarReg:$targetreg, variable_ops),
		"call $targetreg", 
		[(call i32:$targetreg)],
		BT_CallReg>
	{
		bits<5> targetreg;
	
		let Inst{4-0} = targetreg;
	}
}

def : Pat<(call tglobaladdr:$dest),
          (CALLSYM tglobaladdr:$dest)>;
def : Pat<(call texternalsym:$dest),
          (CALLSYM texternalsym:$dest)>;

// XXXX need pattern fragment for VMUX

// selcondresult is (dest, predicate, trueval, falseval)
def selcondresult : SDNode<"VectorProcISD::SEL_COND_RESULT", SDTypeProfile<1, 3, [  
	SDTCisSameAs<0, 2>, SDTCisSameAs<0, 3>]>>;

//
// SELECT pseudo instructions. This architecture doesn't actually have a scalar
// conditional move instruction. These will be replaced in a later pass 
// with a diamond pattern of conditional branches.
//
let usesCustomInserter = 1 in {
	def SELECTI : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		[(set i32:$dest, (selcondresult i32:$pred, i32:$true, i32:$false))]>;

	def SELECTF : Pseudo<
		(outs ScalarReg:$dest),
		(ins ScalarReg:$pred, ScalarReg:$true, ScalarReg:$false),
		[(set f32:$dest, (selcondresult i32:$pred, f32:$true, f32:$false))]>;

	def SELECTVI : Pseudo<
		(outs VectorReg:$dest),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		[(set v16i32:$dest, (selcondresult i32:$pred, v16i32:$true, v16i32:$false))]>;

	def SELECTVF : Pseudo<
		(outs VectorReg:$dest),
		(ins ScalarReg:$pred, VectorReg:$true, VectorReg:$false),
		[(set v16f32:$dest, (selcondresult i32:$pred, v16f32:$true, v16f32:$false))]>;
}

//////////////////////////////////////////////////////////////////
// Misc 
//////////////////////////////////////////////////////////////////

def GET_CONTROL_REG : FormatCInst<
	(outs ScalarReg:$dest),
	(ins i32imm:$cr),
	"getcr $dest, $cr",
	[(set i32:$dest, (int_vp_get_control_reg imm:$cr))],
	FmtC_ControlReg,
	1>
{
	bits <5> cr;
	bits <5> dest;
	
	let Inst{4-0} = cr;
	let Inst{9-5} = dest;
}

def SET_CONTROL_REG : FormatCInst<
	(outs),
	(ins ScalarReg:$src, i32imm:$cr),
	"setcr $src, $cr",
	[],
	FmtC_ControlReg,
	0>
{
	bits <5> cr;
	bits <5> src;

	let Inst{4-0} = cr;
	let Inst{9-5} = src;
}

// Load address within frame
// $expr will actually expand to "fp + <offset>"
def LOAD_FRAME_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins MEMri:$addr),
	"lea $dest, $addr",
	[(set i32:$dest, ADDRri:$addr)]>
{
	bits<20> addr;
	bits<5> dest;

	let Inst{30-28} = FmtB_SS.Value;
	let Inst{27-23} = 5;	// Add
	let Inst{22-10} = addr{17-5};	// Grab the offset part of address
	let Inst{9-5} = dest;
	let Inst{4-0} = addr{4-0};		// base register
}

def : Pat<(i32 (load tconstpool:$addr)), (LW tconstpool:$addr, 0)>;
def : Pat<(f32 (load tconstpool:$addr)), (LW tconstpool:$addr, 0)>;

// Get address of jump table
// This turns into add.i <destreg>, pc, <offset from pc>
def LOAD_JTABLE_ADDR : VPInstruction<
	(outs ScalarReg:$dest),
	(ins JTADDR:$addr),
	"lea $dest, $addr",
	[(set i32:$dest, (jtwrapper tjumptable:$addr))]>
{
	bits<13> addr;
	bits<5> dest;

	let Inst{30-28} = FmtB_SS.Value;
	let Inst{27-23} = 5;    // Add
	let Inst{22-10} = addr; // Offset from PC
	let Inst{9-5} = dest;
	let Inst{4-0} = 31;     // base register (PC)
}

// This should only be invoked for types that will fit in the immediate field 
// of the instruction.  The lowering code will transform other types into
// constant pool loads.
def LOADIMM : FormatBUnmaskedInst<
	(outs ScalarReg:$dest),
	(ins i32imm:$imm),
	"move $dest, $imm",
	[(set i32:$dest, imm:$imm)],
	0x0f,
	FmtB_SS>;

def DFLUSH : FormatDInst<
	(outs),
	(ins ScalarReg:$ptr),
	"dflush $ptr",
	[],
	FmtD_DFlush>
{
	bits<5> ptr;
	let Inst{4-0} = ptr;
}

def MEMBAR : FormatDInst<
	(outs),
	(ins i32imm:$imm1, i32imm:$imm2),
	"membar",
	[(atomic_fence imm:$imm1, imm:$imm2)],
	FmtD_MemBar>;

// Conversions
def : Pat<(v16f32 (bitconvert (v16i32 VectorReg:$src))), (v16f32 VectorReg:$src)>;
def : Pat<(v16i32 (bitconvert (v16f32 VectorReg:$src))), (v16i32 VectorReg:$src)>;
def : Pat<(f32 (bitconvert (i32 ScalarReg:$src))), (f32 ScalarReg:$src)>;
def : Pat<(i32 (bitconvert (f32 ScalarReg:$src))), (i32 ScalarReg:$src)>;
