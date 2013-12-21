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

defm OR     : TwoOpIntArith<"or", or, 0x00>;
defm AND    : TwoOpIntArith<"and", and, 0x01>;
defm XOR    : TwoOpIntArith<"xor", xor, 0x03>;
defm ADDI   : TwoOpIntArith<"add_i", add, 0x05>;
defm SUBI   : TwoOpIntArith<"sub_i", sub, 0x06>;
defm SMULI  : TwoOpIntArith  <"mul_i", mul, 0x07>;
defm SRA    : TwoOpIntArith<"ashr", sra, 0x09>;	
defm SRL    : TwoOpIntArith<"shr", srl, 0x0a>;
defm SLL    : TwoOpIntArith<"shl", shl, 0x0b>;
defm CLZ 	: OneOpIntArith<"clz", ctlz, 0x0c>;
defm CTZ 	: OneOpIntArith<"ctz", cttz, 0x0e>;
defm ADDF   : TwoOpFloatArith<"add_f", fadd, 0x20>;
defm SUBF   : TwoOpFloatArith<"sub_f", fsub, 0x21>;
defm MULF   : TwoOpFloatArith<"mul_f", fmul, 0x22>;
defm RECIP  : OneOpFloatArith<"reciprocal", reciprocal, 0x1c>;

def SEXT16 : FormatAUnmaskedOneOpInst<
	(outs GPR32:$dest), 
	(ins GPR32:$src2),
	"sext_16 $dest, $src2",
	[(set GPR32:$dest, (sext_inreg i32:$src2, i16))],
	0x1e,
	FmtA_SSS>;

def SEXT8 : FormatAUnmaskedOneOpInst<
	(outs GPR32:$dest), 
	(ins GPR32:$src2),
	"sext_8 $dest, $src2",
	[(set GPR32:$dest, (sext_inreg i32:$src2, i8))],
	0x1d,
	FmtA_SSS>;

// XXX need predicated versions of these
def SITOFSS : FormatAUnmaskedOneOpInst<
	(outs GPR32:$dest), 
	(ins GPR32:$src2),
	"itof $dest, $src2",
	[(set f32:$dest, (sint_to_fp i32:$src2))],
	0x2a,
	FmtA_SSS>;

def SITOFVV : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins VR512:$src2),
	"itof $dest, $src2",
	[(set v16f32:$dest, (sint_to_fp v16i32:$src2))],
	0x2a,
	FmtA_VVV>;

def SITOFVS : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins GPR32:$src2),
	"itof $dest, $src2",
	[(set v16f32:$dest, (sint_to_fp (splat i32:$src2)))],
	0x2a,
	FmtA_VVS>;

def FTOSISS : FormatAUnmaskedOneOpInst<
	(outs GPR32:$dest), 
	(ins GPR32:$src2),
	"ftoi $dest, $src2",
	[(set i32:$dest, (fp_to_sint f32:$src2))],
	0x1b,
	FmtA_SSS>;

def FTOSIVV : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins VR512:$src2),
	"ftoi $dest, $src2",
	[(set v16i32:$dest, (fp_to_sint v16f32:$src2))],
	0x1b,
	FmtA_VVV>;

def FTOSIVS : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins GPR32:$src2),
	"ftoi $dest, $src2",
	[(set v16i32:$dest, (fp_to_sint (splat f32:$src2)))],
	0x1b,
	FmtA_VVS>;

defm SGTSI : IntCompareInst<"setgt_i", SETGT, 0x12, int_vp_mask_cmpi_sgt>;	
defm SGESI : IntCompareInst<"setge_i", SETGE, 0x13, int_vp_mask_cmpi_sge>;
defm SLTSI : IntCompareInst<"setlt_i", SETLT, 0x14, int_vp_mask_cmpi_slt>;
defm SLESI : IntCompareInst<"setle_i", SETLE, 0x15, int_vp_mask_cmpi_sle>;
defm SEQSI : IntCompareInst<"seteq_i", SETEQ, 0x10, int_vp_mask_cmpi_eq>;
defm SNESI : IntCompareInst<"setne_i", SETNE, 0x11, int_vp_mask_cmpi_ne>;
defm SGTUI : IntCompareInst<"setgt_u", SETUGT, 0x16, int_vp_mask_cmpi_ugt>;	
defm SGEUI : IntCompareInst<"setge_u", SETUGE, 0x17, int_vp_mask_cmpi_uge>;
defm SLTUI : IntCompareInst<"setlt_u", SETULT, 0x18, int_vp_mask_cmpi_ult>;
defm SLEUI : IntCompareInst<"setle_u", SETULE, 0x19, int_vp_mask_cmpi_ule>;

defm SGTFO : FloatCompareInst<"setgt", SETOGT, 0x2c, int_vp_mask_cmpf_gt>;	
defm SGEFO : FloatCompareInst<"setge", SETOGE, 0x2d, int_vp_mask_cmpf_ge>;
defm SLTFO : FloatCompareInst<"setlt", SETOLT, 0x2e, int_vp_mask_cmpf_lt>;
defm SLEFO : FloatCompareInst<"setle", SETOLE, 0x2f, int_vp_mask_cmpf_le>;
	
// Note: there is no floating point eq/ne.  Just use integer
// forms
def : Pat<(int_vp_mask_cmpf_eq v16f32:$src1, v16f32:$src2),
	(SEQSIVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_eq v16f32:$src1, (splat f32:$src2)),
	(SEQSIVS  v16f32:$src1, f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ne v16f32:$src1, v16f32:$src2),
	(SNESIVV  v16f32:$src1, v16f32:$src2)>;
def : Pat<(int_vp_mask_cmpf_ne v16f32:$src1, (splat f32:$src2)),
	(SNESIVS  v16f32:$src1, f32:$src2)>;

def GET_LANEI : FormatAUnmaskedTwoOpInst<
	(outs GPR32:$dest),
	(ins VR512:$src1, GPR32:$src2),
	"getlane $dest, $src1, $src2",	// XXX this isn't a good name, replace
	[(set i32:$dest, (extractelt v16i32:$src1, i32:$src2))],
	0x1a,
	FmtA_VVS>;

def GET_LANEIimm : FormatBUnmaskedInst<
	(outs GPR32:$dest),
	(ins VR512:$src1, i32imm:$imm),
	"getlane $dest, $src1, $imm",
	[(set i32:$dest, (extractelt v16i32:$src1, simm13:$imm))],
	0x1a,
	FmtB_VV>;

def : Pat<(extractelt v16f32:$src1, i32:$src2),
	(GET_LANEI v16f32:$src1, i32:$src2)>; 
def : Pat<(extractelt v16f32:$src1, simm13:$imm),
	(GET_LANEIimm v16f32:$src1, imm:$imm)>; 

def SHUFFLEI : FormatAUnmaskedTwoOpInst<
	(outs VR512:$dest),
	(ins VR512:$src1, VR512:$src2),
	"shuffle $dest, $src1, $src2",
	[(set v16i32:$dest, (int_vp_shufflei v16i32:$src1, v16i32:$src2))],
	0x0d,
	FmtA_VVV>;
	
let Constraints = "$dest = $oldvalue" in {
	def SHUFFLEI_MASK : FormatAMaskedTwoOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, VR512:$src1, VR512:$src2, VR512:$oldvalue),
		"shuffle_mask $dest, $mask, $src1, $src2",
		[(set v16i32:$dest, (int_vp_blendi i32:$mask, (int_vp_shufflei v16i32:$src1, 
			v16i32:$src2), v16i32:$oldvalue))],
		0x0d,
		FmtA_VVVM>;

	def SHUFFLEI_MASKinv : FormatAMaskedTwoOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, VR512:$src1, VR512:$src2, VR512:$oldvalue),
		"shuffle_invmask $dest, $mask, $src1, $src2",
		[(set v16i32:$dest, (int_vp_blendi (not i32:$mask), (int_vp_shufflei v16i32:$src1, 
			v16i32:$src2), v16i32:$oldvalue))],
		0x0d,
		FmtA_VVVMinv>;
}

// Floating point shuffle forms
def : Pat<(int_vp_shufflef v16f32:$src1, v16i32:$src2), 
	(SHUFFLEI v16f32:$src1, v16i32:$src2)>;
def : Pat<(int_vp_blendf i32:$mask, (int_vp_shufflef v16f32:$src1, v16i32:$src2), 
	v16f32:$oldvalue), 
	(SHUFFLEI_MASK i32:$mask, v16f32:$src1, v16i32:$src2, v16f32:$oldvalue)>;
def : Pat<(int_vp_blendf (not i32:$mask), (int_vp_shufflef v16f32:$src1, v16i32:$src2), 
	v16f32:$oldvalue), 
	(SHUFFLEI_MASKinv i32:$mask, v16f32:$src1, v16i32:$src2, v16f32:$oldvalue)>;

def MOVESS : FormatAUnmaskedOneOpInst<
	(outs GPR32:$dest), 
	(ins GPR32:$src2),
	"move $dest, $src2",
	[],
	0xf,
	FmtA_SSS>;

// This should only be invoked for types that will fit in the immediate field 
// of the instruction.  The lowering code will transform other types into
// constant pool loads.
def MOVESSimm : FormatBUnmaskedInst<
	(outs GPR32:$dest),
	(ins i32imm:$imm),
	"move $dest, $imm",
	[(set i32:$dest, imm:$imm)],
	0x0f,
	FmtB_SS>;

def MOVEVSI : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins GPR32:$src2),
	"move $dest, $src2",
	[(set v16i32:$dest, (splat i32:$src2))],
	0xf,
	FmtA_VVS>;
	
def : Pat<(v16f32 (splat f32:$src2)), (MOVEVSI f32:$src2)>;

def MOVEVV : FormatAUnmaskedOneOpInst<
	(outs VR512:$dest), 
	(ins VR512:$src2),
	"move $dest, $src2",
	[],
	0xf,
	FmtA_VVV>;

// Predicated
let Constraints = "$dest = $oldvalue" in {
	def MOVEVVMI : FormatAMaskedOneOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
		"move_mask $dest, $mask, $src2",
		[(set v16i32:$dest, (int_vp_blendi i32:$mask, v16i32:$src2, v16i32:$oldvalue))],
		0xf,
		FmtA_VVVM>;

	def MOVEVVMIinv : FormatAMaskedOneOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, VR512:$src2, VR512:$oldvalue),
		"move_invmask $dest, $mask, $src2",
		[(set v16i32:$dest, (int_vp_blendi (not i32:$mask), v16i32:$src2, v16i32:$oldvalue))],
		0xf,
		FmtA_VVVMinv>;

	def MOVEVSMI : FormatAMaskedOneOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
		"move_mask $dest, $mask, $src2",
		[(set v16i32:$dest, (int_vp_blendi i32:$mask, (splat i32:$src2), v16i32:$oldvalue))],
		0xf,
		FmtA_VVSM>;

	def MOVEVSMIinv : FormatAMaskedOneOpInst<
		(outs VR512:$dest),
		(ins GPR32:$mask, GPR32:$src2, VR512:$oldvalue),
		"move_invmask $dest, $mask, $src2",
		[(set v16i32:$dest, (int_vp_blendi (not i32:$mask), (splat i32:$src2), v16i32:$oldvalue))],
		0xf,
		FmtA_VVSMinv>;
}

def : Pat<(int_vp_blendf i32:$mask, v16f32:$src2, v16f32:$oldvalue), 
	(MOVEVVMI i32:$mask, v16f32:$src2, v16f32:$oldvalue)>;
def : Pat<(int_vp_blendf (not i32:$mask), v16f32:$src2, v16f32:$oldvalue), 
	(MOVEVVMIinv i32:$mask, v16f32:$src2, v16f32:$oldvalue)>;
def : Pat<(int_vp_blendf i32:$mask, (splat f32:$src2), v16f32:$oldvalue),
	(MOVEVSMI i32:$mask, f32:$src2, v16f32:$oldvalue)>; 
def : Pat<(int_vp_blendf (not i32:$mask), (splat f32:$src2), v16f32:$oldvalue),
	(MOVEVSMIinv i32:$mask, f32:$src2, v16f32:$oldvalue)>; 

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

def : Pat<(i32 (extloadi1 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi8 ADDRri:$addr)), (LBU ADDRri:$addr)>;
def : Pat<(i32 (extloadi16 ADDRri:$addr)), (LSS ADDRri:$addr)>;
def : Pat<(f32 (load ADDRri:$addr)), (LW ADDRri:$addr)>;
def : Pat<(store f32:$srcDest, ADDRri:$addr), (SW f32:$srcDest, ADDRri:$addr)>;

def LOAD_SYNC : FormatCUnmaskedInst<
	(outs GPR32:$srcDest),
	(ins MEMri:$addr),
	"load_sync $srcDest, $addr",
	[],
	FmtC_Sync,
	1>;

def STORE_SYNC : FormatCUnmaskedInst<
	(outs GPR32:$result),
	(ins GPR32:$srcDest, MEMri:$addr),
	"store_sync $srcDest, $addr	",
	[],
	FmtC_Sync,
	0>
{
	let Constraints = "$result = $srcDest";
}

// Vector
def BLOCK_LOADI : FormatCUnmaskedInst<
	(outs VR512:$srcDest),
	(ins MEMri:$addr),
	"load_v $srcDest, $addr",
	[(set v16i32:$srcDest, (load ADDRri:$addr))],
	FmtC_Block,
	1>;

def BLOCK_STOREI : FormatCUnmaskedInst<
	(outs),
	(ins VR512:$srcDest, MEMri:$addr),
	"store_v $srcDest, $addr",
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
	(outs VR512:$srcDest),
	(ins MEMri:$addr, GPR32:$mask),
	"load_v_mask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_block_loadi_masked ADDRri:$addr, i32:$mask))],
	FmtC_BlockMasked,
	1>;

def INT_BLOCK_LOADI_INVMASKED : FormatCMaskedInst<
	(outs VR512:$srcDest),
	(ins MEMri:$addr, GPR32:$mask),
	"load_v_invmask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_block_loadi_masked ADDRri:$addr, (not i32:$mask)))],
	FmtC_BlockInvMasked,
	1>;

def : Pat<(int_vp_block_loadf_masked ADDRri:$addr, i32:$mask),
	(INT_BLOCK_LOADI_MASKED ADDRri:$addr, i32:$mask)>;
def : Pat<(int_vp_block_loadf_masked ADDRri:$addr, (not i32:$mask)),
	(INT_BLOCK_LOADI_INVMASKED ADDRri:$addr, i32:$mask)>;

def INT_GATHER_LOADI : FormatCUnmaskedInst<
	(outs VR512:$srcDest),
	(ins VMEMri:$addr),
	"load_gath $srcDest, $addr",
	[(set v16i32:$srcDest, (int_vp_gather_loadi VADDRri:$addr))],
	FmtC_ScGath,
	1>;

def INT_GATHER_LOADI_MASKED : FormatCMaskedInst<
	(outs VR512:$srcDest),
	(ins VMEMri:$addr, GPR32:$mask),
	"load_gath_mask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_gather_loadi_masked VADDRri:$addr, i32:$mask))],
	FmtC_ScGathMasked,
	1>;

def INT_GATHER_LOADI_INVMASKED : FormatCMaskedInst<
	(outs VR512:$srcDest),
	(ins VMEMri:$addr, GPR32:$mask),
	"load_gath_invmask $srcDest, $mask, $addr",
	[(set v16i32:$srcDest, (int_vp_gather_loadi_masked VADDRri:$addr, (not i32:$mask)))],
	FmtC_ScGathInvMasked,
	1>;

def : Pat<(int_vp_gather_loadf VADDRri:$addr), (INT_GATHER_LOADI VADDRri:$addr)>;
def : Pat<(int_vp_gather_loadf_masked VADDRri:$addr, i32:$mask),
	(INT_GATHER_LOADI_MASKED VADDRri:$addr, i32:$mask)>;
def : Pat<(int_vp_gather_loadf_masked VADDRri:$addr, (not i32:$mask)),
	(INT_GATHER_LOADI_INVMASKED VADDRri:$addr, i32:$mask)>;

def INT_STRIDED_LOADI : FormatCUnmaskedInst<
	(outs VR512:$srcDest),
	(ins MEMri:$addr),
	"load_strd $srcDest, $addr",
	[],	// Assembler only...
	FmtC_Strided,
	1>;

def INT_STRIDED_LOADI_MASKED : FormatCMaskedInst<
	(outs VR512:$srcDest),
	(ins MEMri:$addr, GPR32:$mask),
	"load_strd_mask $srcDest, $mask, $addr",
	[],	// Assembler only...
	FmtC_StridedMasked,
	1>;

def INT_STRIDED_LOADI_INVMASKED : FormatCMaskedInst<
	(outs VR512:$srcDest),
	(ins MEMri:$addr, GPR32:$mask),
	"load_strd_invmask $srcDest, $mask, $addr",
	[],	// Assembler only...
	FmtC_StridedInvMasked,
	1>;

let hasSideEffects = 1, mayStore = 1 in {
	def INT_SCATTER_STOREI : FormatCUnmaskedInst<
		(outs),
		(ins VR512:$srcDest, VMEMri:$addr),
		"store_scat $srcDest, $addr",
		[(int_vp_scatter_storei VADDRri:$addr, v16i32:$srcDest)],
		FmtC_ScGath,
		0>;

	def INT_SCATTER_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, VMEMri:$addr, GPR32:$mask),
		"store_scat_mask $srcDest, $mask, $addr",
		[(int_vp_scatter_storei_masked VADDRri:$addr, v16i32:$srcDest, i32:$mask)],
		FmtC_ScGathMasked,
		0>;

	def INT_SCATTER_STOREI_INVMASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, VMEMri:$addr, GPR32:$mask),
		"store_scat_invmask $srcDest, $mask, $addr",
		[(int_vp_scatter_storei_masked VADDRri:$addr, v16i32:$srcDest, (not i32:$mask))],
		FmtC_ScGathInvMasked,
		0>;

	def INT_STRIDED_STOREI : FormatCUnmaskedInst<
		(outs),
		(ins VR512:$srcDest, MEMri:$addr),
		"store_strd $srcDest, $addr",
		[],	// Assembly only
		FmtC_Strided,
		0>;

	def INT_STRIDED_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, MEMri:$addr, GPR32:$mask),
		"store_strd_mask $srcDest, $mask, $addr",
		[],	// Assembly only
		FmtC_StridedMasked,
		0>;

	def INT_STRIDED_STOREI_INVMASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, MEMri:$addr, GPR32:$mask),
		"store_strd_invmask $srcDest, $mask, $addr",
		[],	// Assembly only
		FmtC_StridedInvMasked,
		0>;

	def INT_BLOCK_STOREI_MASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, MEMri:$addr, GPR32:$mask),
		"store_v_mask $srcDest, $mask, $addr",
		[(int_vp_block_storei_masked ADDRri:$addr, v16i32:$srcDest, i32:$mask)],
		FmtC_BlockMasked,
		0>;

	def INT_BLOCK_STOREI_INVMASKED : FormatCMaskedInst<
		(outs),
		(ins VR512:$srcDest, MEMri:$addr, GPR32:$mask),
		"store_v_invmask $srcDest, $mask, $addr",
		[(int_vp_block_storei_masked ADDRri:$addr, v16i32:$srcDest, (not i32:$mask))],
		FmtC_BlockInvMasked,
		0>;
}

def : Pat<(int_vp_scatter_storef VADDRri:$addr, v16f32:$srcDest),
	(INT_SCATTER_STOREI v16f32:$srcDest, VADDRri:$addr)>;
def : Pat<(int_vp_scatter_storef_masked VADDRri:$addr, v16f32:$srcDest, i32:$mask),
	(INT_SCATTER_STOREI_MASKED v16f32:$srcDest, VADDRri:$addr, i32:$mask)>;
def : Pat<(int_vp_block_storef_masked ADDRri:$addr, v16f32:$srcDest, i32:$mask),
	(INT_BLOCK_STOREI_MASKED v16f32:$srcDest, ADDRri:$addr, i32:$mask)>;

// Atomics	
let usesCustomInserter = 1 in {
	def ATOMIC_LOAD_ADD : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$amt),
		[(set i32:$dest, (atomic_load_add GPR32:$ptr, GPR32:$amt))]>;

	def ATOMIC_LOAD_SUB : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$amt),
		[(set i32:$dest, (atomic_load_sub GPR32:$ptr, GPR32:$amt))]>;

	def ATOMIC_LOAD_AND : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$amt),
		[(set i32:$dest, (atomic_load_and GPR32:$ptr, GPR32:$amt))]>;

	def ATOMIC_LOAD_OR : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$amt),
		[(set i32:$dest, (atomic_load_or GPR32:$ptr, GPR32:$amt))]>;

	def ATOMIC_LOAD_XOR : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$amt),
		[(set i32:$dest, (atomic_load_xor GPR32:$ptr, GPR32:$amt))]>;

	def ATOMIC_CMP_SWAP : Pseudo<
		(outs GPR32:$dest),
		(ins GPR32:$ptr, GPR32:$cmp, GPR32:$swap),
		[(set i32:$dest, (atomic_cmp_swap GPR32:$ptr, GPR32:$cmp, 
			GPR32:$swap))]>;
}	

//////////////////////////////////////////////////////////////////
// Cache Control (format D)
//////////////////////////////////////////////////////////////////

def DFLUSH : FormatDOneOp<
	(outs),
	(ins GPR32:$ptr),
	"dflush $ptr",
	[],
	FmtD_DFlush>;

def DINVALIDATE : FormatDOneOp<
	(outs),
	(ins GPR32:$ptr),
	"dinvalidate $ptr",
	[],
	FmtD_DInvalidate>;

def IINVALIDATE : FormatDOneOp<
	(outs),
	(ins GPR32:$ptr),
	"iinvalidate $ptr",
	[],
	FmtD_IInvalidate>;

def MEMBAR : FormatDInst<
	(outs),
	(ins i32imm:$imm1, i32imm:$imm2),
	"membar",
	[(atomic_fence imm:$imm1, imm:$imm2)],
	FmtD_MemBar>;

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
		(ins GPR32:$test, brtarget:$dest),
		"bfalse $test, $dest",
		[(brcond (i32 (seteq i32:$test, 0)), bb:$dest)],
		BT_IfFalse>;

	def BTRUE : ConditionalBranchInst<
		(outs), 
		(ins GPR32:$test, brtarget:$dest),
		"btrue $test, $dest",
		[(brcond i32:$test, bb:$dest)],
		BT_IfTrue>;

	def BALL: ConditionalBranchInst<
		(outs),
		(ins GPR32:$test, brtarget:$dest),
		"ball $test, $dest",
		[],	// assembler only XXX expose this to compiler
		BT_All>;

	def BNALL: ConditionalBranchInst<
		(outs),
		(ins GPR32:$test, brtarget:$dest),
		"bnall $test, $dest",
		[], // assembler only XXX expose this to compiler
		BT_NAll>;

	// Converts to MOVE pc, <srcreg>
	def JUMPREG : VPInstruction<
		(outs), 
		(ins GPR32:$dest),
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
		(ins GPR32:$tableptr, GPR32:$jt),
		"load_32 pc, ( $tableptr )",
		[(brjt i32:$tableptr, tjumptable:$jt)]>
	{
		let isBranch = 1;
		let isIndirectBranch = 1;
		let isBarrier = 1;
		let isCodeGenOnly = 1;  // Don't use this for assembler or disassembler

		bits<5> tableptr;

		let Inst{31} = 1;
		let Inst{29} = 1;		// Is load
		let Inst{28-25} = 4;	// Scalar, 32-bit
		let Inst{9-5} = 31;		// PC is destination
		let Inst{4-0} = tableptr;	// Register holds computed pointer into table
	}
}

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
}

let Defs = [SP_REG], Uses = [SP_REG], hasSideEffects = 1 in {
	def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
								   [(callseq_start timm:$amt)]>;
	def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
								[(callseq_end timm:$amt1, timm:$amt2)]>;
}

// Note: Unlike other branches, call is not a terminator: it does not end a 
// basic block.
let isCall = 1, Defs = [ LINK_REG ] in {
	def CALLSYM : UnconditionalBranchInst<
		(outs), 
		(ins calltarget:$dest, variable_ops),
		"call $dest", 
		[],
		BT_Call>;

	def CALLREG : UnconditionalBranchInst<
		(outs), 
		(ins GPR32:$targetreg, variable_ops),
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

def GET_CONTROL_REG : FormatCInst<
	(outs GPR32:$dest),
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
	(ins GPR32:$src, i32imm:$cr),
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

def LOAD_EFFECTIVE_ADDR : VPInstruction<
	(outs GPR32:$dest),
	(ins LEAri:$addr),
	"lea $dest, $addr",
	[(set i32:$dest, ADDRri:$addr)]>
{
	let isAsmParserOnly = 1; 	// Don't disassemble

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
	(outs GPR32:$dest),
	(ins JTADDR:$addr),
	"lea $dest, $addr",
	[(set i32:$dest, (jtwrapper tjumptable:$addr))]>
{
	let isCodeGenOnly = 1;  // Don't use for assembler or disassembler
  
	bits<13> addr;
	bits<5> dest;

	let Inst{30-28} = FmtB_SS.Value;
	let Inst{27-23} = 5;    // Add
	let Inst{22-10} = addr; // Offset from PC
	let Inst{9-5} = dest;
	let Inst{4-0} = 31;     // base register (PC)
}

def NOP : VPInstruction<
	(outs),
	(ins),
	"nop",
	[]>;

// Conversions
def : Pat<(v16f32 (bitconvert (v16i32 VR512:$src))), (v16f32 VR512:$src)>;
def : Pat<(v16i32 (bitconvert (v16f32 VR512:$src))), (v16i32 VR512:$src)>;
def : Pat<(f32 (bitconvert (i32 GPR32:$src))), (f32 GPR32:$src)>;
def : Pat<(i32 (bitconvert (f32 GPR32:$src))), (i32 GPR32:$src)>;
