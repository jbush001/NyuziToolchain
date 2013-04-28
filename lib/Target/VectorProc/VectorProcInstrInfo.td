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


def simm8  : PatLeaf<(imm), [{ return isInt<8>(N->getSExtValue()); }]>;
def simm10  : PatLeaf<(imm), [{ return isInt<10>(N->getSExtValue()); }]>;
def simm13  : PatLeaf<(imm), [{ return isInt<13>(N->getSExtValue()); }]>;
def simm20  : PatLeaf<(imm), [{ return isInt<20>(N->getSExtValue()); }]>;

class VPInstruction<dag outputs, dag inputs, string asmString, list<dag> pattern>
	: Instruction {
	let Namespace = "SP";
	dag OutOperandList = outputs;
	dag InOperandList = inputs;
	let AsmString = asmString;
	let Pattern = pattern;
}

multiclass VPTernaryIntArith<string operator, SDNode OpNode> {
	// Instruction format A, integer
	def rr : VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$b, ScalarRegs:$c),
		!strconcat("s$dst = s$b ", !strconcat(operator, " s$c")),
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;

	// Instruction format B
	def ri : VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$b, i32imm:$c),
		!strconcat("s$dst = s$b ", !strconcat(operator, " $c")),
		[(set i32:$dst, (OpNode i32:$b, simm13:$c))]>;
}

class VPTernaryFloatArith<string operator, SDNode OpNode> 
	: VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$b, ScalarRegs:$c),
		!strconcat("f$dst = f$b ", !strconcat(operator, " f$c")),
		[(set ScalarRegs:$dst, (OpNode (f32 ScalarRegs:$b), (f32 ScalarRegs:$c)))]>;

defm AND    : VPTernaryIntArith<"&", and>;
defm OR     : VPTernaryIntArith<"|", or>;
defm XOR    : VPTernaryIntArith<"^", xor>;
defm SLL    : VPTernaryIntArith<"<<", shl>;
defm SRL    : VPTernaryIntArith<">>", srl>;
defm SRA    : VPTernaryIntArith<">>", sra>;	// XXX need to use U register.
defm ADDI   : VPTernaryIntArith<"+", add>;
defm SUBI   : VPTernaryIntArith<"-", add>;
defm SMULI  : VPTernaryIntArith  <"*", mul>;
def ADDF    : VPTernaryFloatArith<"+", fadd>;
def SUBF    : VPTernaryFloatArith<"-", fsub>;
def MULF    : VPTernaryFloatArith<"*", fmul>;

// This is kind of a kludge
def CONV : VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$src),
		"s$dst = s$src",
		[(set ScalarRegs:$dst, (f32 ScalarRegs:$src))]>;


def SITOF : VPInstruction<
			(outs ScalarRegs:$dst), 
			(ins ScalarRegs:$src),
            "f$dst = itof(s$src)",
        	[(set f32:$dst, (sint_to_fp i32:$src))]>;

def FTOSI : VPInstruction<
			(outs ScalarRegs:$dst), 
			(ins ScalarRegs:$src),
        	"s$dst= ftoi(f$src)",
        	[(set i32:$dst, (fp_to_sint f32:$src))]>;

def MOVEREG : VPInstruction<
			(outs ScalarRegs:$dst), 
			(ins ScalarRegs:$src),
        	"s$dst = s$src",
        	[]>;

def brtarget : Operand<OtherVT>;

multiclass CONDI<string operator, CondCode condition> {
	// Instruction format A, integer
	def rr : VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$a, ScalarRegs:$b),
		!strconcat("s$dst = s$a ", !strconcat(operator, " s$b")),
		[(set i32:$dst, (selectcc i32:$a, i32:$b, 1, 0, condition))]>;

	// Instruction format B
	def ri : VPInstruction<
		(outs ScalarRegs:$dst), 
		(ins ScalarRegs:$a, i32imm:$b),
		!strconcat("s$dst = s$a ", !strconcat(operator, " $b")),
		[(set i32:$dst, (selectcc i32:$a, simm13:$b, 1, 0, condition))]>;
}

class CONDF<string operator, CondCode condition>
	: VPInstruction<
		(outs ScalarRegs:$dst),
		(ins ScalarRegs:$a, ScalarRegs:$b),
		!strconcat("s$dst = f$a ", !strconcat(operator, " f$b")),
		[(set i32:$dst, (selectcc f32:$a, f32:$b, 1, 0, condition))]>
{
}

defm SGTI : CONDI<">", SETGT>;	 // XXX does not handle unsigned
defm SGEI : CONDI<">=", SETGE>;
defm SLTI : CONDI<"<", SETLT>;
defm SLEI : CONDI<"<=", SETLE>;
defm SEQI : CONDI<"==", SETEQ>;
defm SNEI : CONDI<"!=", SETNE>;
def SGTFO : CONDF<">", SETOGT>;	// Note: unordered and ordered treated the same
def SGEFO : CONDF<">=", SETOGE>;
def SLTFO : CONDF<"<", SETOLT>;
def SLEFO : CONDF<"<=", SETOLE>;
def SEQFO : CONDF<"==", SETOEQ>;
def SNEFO : CONDF<"!=", SETONE>;
def SGTFU : CONDF<">", SETUGT>;
def SGEFU : CONDF<">=", SETUGE>;
def SLTFU : CONDF<"<", SETULT>;
def SLEFU : CONDF<"<=", SETULE>;
def SEQFU : CONDF<"==", SETUEQ>;
def SNEFU : CONDF<"!=", SETUNE>;

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
	(ins ScalarRegs:$rs, brtarget:$offset),
	"if !s$rs goto $offset",
	[(brcond (i32 (seteq i32:$rs, 0)), bb:$offset)]> ;

def IFTRUE	: BranchInstruction<
	(outs), 
	(ins ScalarRegs:$rs, brtarget:$offset),
	"if s$rs goto $offset",
	[(brcond i32:$rs, bb:$offset)]> ;

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;

def MEMri : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, i32imm);
}

multiclass MEMLOAD<string suffix, string regtype, PatFrag op>  {
	def i : VPInstruction<
		(outs ScalarRegs:$dst),
		(ins MEMri:$addr),
		!strconcat(!strconcat(!strconcat(regtype, "$dst = mem_"), suffix), "[$addr]"),
		[(set i32:$dst, (i32 (op ADDRri:$addr)))]>;

	def f : VPInstruction<
		(outs ScalarRegs:$dst),
		(ins MEMri:$addr),
		!strconcat(!strconcat(!strconcat(regtype, "$dst = mem_"), suffix), "[$addr]"),
		[(set f32:$dst, (op ADDRri:$addr))]>;
}

let hasSideEffects = 1, mayStore = 1 in {
	multiclass MEMSTORE<string suffix, PatFrag op>  {
		def i : VPInstruction<
			(outs),
			(ins MEMri:$addr, ScalarRegs:$src),
			!strconcat("mem_", !strconcat(suffix, "[$addr] = s$src")),
			[(op i32:$src, ADDRri:$addr)]>;

		def f : VPInstruction<
			(outs),
			(ins MEMri:$addr, ScalarRegs:$src),
			!strconcat("mem_", !strconcat(suffix, "[$addr] = s$src")),
			[(op f32:$src, ADDRri:$addr)]>;
	}
}

defm LBS : MEMLOAD<"b", "s", sextloadi8>;
defm LBU : MEMLOAD<"b", "u", zextloadi8>;
defm LSS : MEMLOAD<"s", "s", sextloadi16>;
defm LSU : MEMLOAD<"s", "u", zextloadi16>;
defm LW : MEMLOAD<"l", "s", load>;
defm SB : MEMSTORE<"b", truncstorei8>;
defm SS : MEMSTORE<"s", truncstorei16>;
defm SW : MEMSTORE<"l", store>;

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSSi ADDRri:$src)>;

def LOADIMM : VPInstruction<
	(outs ScalarRegs:$dest),
	(ins i32imm:$val),
	"s$dest = $val",
	[(set ScalarRegs:$dest, simm13:$val)]>;

def SDT_SPRet : SDTypeProfile<0, 1, [SDTCisVT<0, i32>]>;
def retflag : SDNode<"SPISD::RET_FLAG", 
	SDT_SPRet,
    [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

let isReturn = 1, isTerminator = 1 in {
	def RET : VPInstruction<
		(outs),
		(ins i32imm:$val),
		"pc = link",
		[(retflag simm13:$val)]>;
}


////////////////////////////////////////////////////////////

class F2<dag outs, dag ins, string asmstr, list<dag> pattern>
   : VPInstruction<outs, ins, asmstr, pattern> {
  bits<3>  op2;
  bits<22> imm22;
}

class F2_1<bits<3> op2Val, dag outs, dag ins, string asmstr, list<dag> pattern>
   : F2<outs, ins, asmstr, pattern> {
  bits<5>  rd;

}

class F3<dag outs, dag ins, string asmstr, list<dag> pattern>
    : VPInstruction<outs, ins, asmstr, pattern> {
  bits<5> rd;
  bits<6> op3;
  bits<5> rs1;
}

class F3_1<bits<2> opVal, bits<6> op3val, dag outs, dag ins,
           string asmstr, list<dag> pattern> : F3<outs, ins, asmstr, pattern> {
  bits<8> asi = 0; // asi not currently used
  bits<5> rs2;

 
}

class F3_2<bits<2> opVal, bits<6> op3val, dag outs, dag ins, 
           string asmstr, list<dag> pattern> : F3<outs, ins, asmstr, pattern> {
  bits<13> simm13;

}

// Branch targets have OtherVT type.
def calltarget : Operand<i32>;

//  These are target-independent nodes, but have target-specific formats.
def SDT_SPCallSeqStart : SDCallSeqStart<[ SDTCisVT<0, i32> ]>;
def SDT_SPCallSeqEnd   : SDCallSeqEnd<[ SDTCisVT<0, i32>,
                                        SDTCisVT<1, i32> ]>;

def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SPCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END",   SDT_SPCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def SDT_SPCall    : SDTypeProfile<0, -1, [SDTCisVT<0, i32>]>;
def call          : SDNode<"SPISD::CALL", SDT_SPCall,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                            SDNPVariadic]>;


def flushw        : SDNode<"SPISD::FLUSHW", SDTNone,
                           [SDNPHasChain, SDNPSideEffect, SDNPMayStore]>;

def getPCX        : Operand<i32> {
  let PrintMethod = "printGetPCX";
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

// Pseudo instructions.
class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
   : VPInstruction<outs, ins, asmstr, pattern>;

let Defs = [S29], Uses = [S29] in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i32imm:$amt),
                               "!ADJCALLSTACKDOWN $amt",
                               [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                            "!ADJCALLSTACKUP $amt1",
                            [(callseq_end timm:$amt1, timm:$amt2)]>;
}

let hasSideEffects = 1, mayStore = 1 in {
  let rd = 0, rs1 = 0, rs2 = 0 in
    def FLUSHW : F3_1<0b10, 0b101011, (outs), (ins),
                      "flushw",
                      [(flushw)]>, Requires<[]>;
  let rd = 0, rs1 = 1, simm13 = 3 in
    def TA3 : F3_2<0b10, 0b111010, (outs), (ins),
                   "ta 3",
                   [(flushw)]>;
}

def UNIMP : F2_1<0b000, (outs), (ins i32imm:$val),
                "unimp $val", []>;


def LEA_ADDri   : F3_2<2, 0b000000,
                   (outs ScalarRegs:$dst), (ins MEMri:$addr),
                   "$dst = ${addr:arith}",
                   [(set i32:$dst, ADDRri:$addr)]>;

let Uses = [S29],
    hasDelaySlot = 1, isCall = 1,
    Defs = [S0, S1, S2, S3, S4 ] in {
  def CALL : VPInstruction<(outs), (ins calltarget:$dst, variable_ops),
                    "call $dst", []> {
    bits<30> disp;
  }

  def JMPLri : F3_2<2, 0b111000,
                    (outs), (ins MEMri:$ptr, variable_ops),
                    "call $ptr",
                    [(call ADDRri:$ptr)]>;
}

//===----------------------------------------------------------------------===//
// Non-Instruction Patterns
//===----------------------------------------------------------------------===//

// Calls: 
def : Pat<(call tglobaladdr:$dst),
          (CALL tglobaladdr:$dst)>;
def : Pat<(call texternalsym:$dst),
          (CALL texternalsym:$dst)>;

