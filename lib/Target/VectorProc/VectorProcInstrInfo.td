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

def ADDRri : ComplexPattern<iPTR, 2, "SelectADDRri", [frameindex], []>;

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
		(outs IntRegs:$dst), 
		(ins IntRegs:$b, IntRegs:$c),
		!strconcat("s$dst = s$b ", !strconcat(operator, " s$c")),
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;

	// Instruction format B
	def ri : VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$b, i32imm:$c),
		!strconcat("s$dst = s$b ", !strconcat(operator, " s$c")),
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;	// XXXX simm13
}

class VPTernaryFloatArith<string operator, SDNode OpNode> 
	: VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$b, IntRegs:$c),
		!strconcat("f$dst = f$b ", !strconcat(operator, " f$c")),
		[(set IntRegs:$dst, (OpNode (f32 IntRegs:$b), (f32 IntRegs:$c)))]>;

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

def SDTSPFTOI : SDTypeProfile<1, 1, [SDTCisVT<0, f32>, SDTCisFP<1>]>;
def SDTSPITOF : SDTypeProfile<1, 1, [SDTCisFP<0>, SDTCisVT<1, f32>]>;
def SPftoi  : SDNode<"SPISD::FTOI", SDTSPFTOI>;
def SPitof  : SDNode<"SPISD::ITOF", SDTSPITOF>;

// This is kind of a kludge
def CONV : VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$src),
		"s$dst = s$src",
		[(set IntRegs:$dst, (f32 IntRegs:$src))]>;


def SITOF : VPInstruction<
			(outs IntRegs:$dst), 
			(ins IntRegs:$src),
            "f$dst = itof(s$src)",
        	[(set f32:$dst, (sint_to_fp i32:$src))]>;

def FTOSI : VPInstruction<
			(outs IntRegs:$dst), 
			(ins IntRegs:$src),
        	"s$dst= ftoi($src)",
        	[(set i32:$dst, (fp_to_sint f32:$src))]>;

def brtarget : Operand<OtherVT>;

multiclass CONDI<string operator, CondCode condition> {
	// Instruction format A, integer
	def rr : VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$a, IntRegs:$b),
		!strconcat("s$dst = s$a ", !strconcat(operator, " s$b")),
		[(set i32:$dst, (selectcc i32:$a, i32:$b, 1, 0, condition))]>;

	// Instruction format B
	def ri : VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$a, i32imm:$b),
		!strconcat("s$dst = s$a ", !strconcat(operator, " s$b")),
		[(set i32:$dst, (selectcc i32:$a, i32:$b, 1, 0, condition))]>;
}

class CONDF<string operator, CondCode condition>
	: VPInstruction<
		(outs IntRegs:$dst),
		(ins IntRegs:$a, IntRegs:$b),
		!strconcat("s$dst = f$a ", !strconcat(operator, " f$b")),
		[(set i32:$dst, (selectcc (f32 IntRegs:$a), (f32 IntRegs:$b), 1, 0, condition))]>
{
}

defm SGTI : CONDI<">", SETGT>;
defm SGEI : CONDI<">=", SETGE>;
defm SLTI : CONDI<"<", SETLT>;
defm SLEI : CONDI<"<=", SETLE>;
defm SEQI : CONDI<"==", SETEQ>;
defm SNEI : CONDI<"!=", SETNE>;
def SGTF : CONDF<">", SETGT>;
def SGEF : CONDF<">=", SETGE>;
def SLTF : CONDF<"<", SETLT>;
def SLEF : CONDF<"<=", SETLE>;
def SEQF : CONDF<"==", SETEQ>;
def SNEF : CONDF<"!=", SETNE>;

def GOTO : VPInstruction<
	(outs),
	(ins brtarget:$offset),
	"goto $offset",
	[(br bb:$offset)]>;

def IFFALSE	: VPInstruction<
  	(outs), 
  	(ins IntRegs:$rs, brtarget:$offset),
    "if !s$rs goto $offset",
    [(brcond (i32 (seteq i32:$rs, 0)), bb:$offset)]> ;

def IFTRUE	: VPInstruction<
  	(outs), 
  	(ins IntRegs:$rs, brtarget:$offset),
    "if s$rs goto $offset",
    [(brcond i32:$rs, bb:$offset)]> ;

def MEMri : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, i32imm);
}

multiclass MEMLOAD<string suffix, string regtype, PatFrag op>  {
	def i : VPInstruction<
		(outs IntRegs:$dst),
		(ins MEMri:$addr),
		!strconcat(!strconcat(!strconcat(suffix, "$dst = mem_"), regtype), "[s$addr]"),
		[(set i32:$dst, (i32 (op ADDRri:$addr)))]>;

	def f : VPInstruction<
		(outs IntRegs:$dst),
		(ins MEMri:$addr),
		!strconcat(!strconcat(!strconcat(suffix, "$dst = mem_"), regtype), "[s$addr]"),
		[(set f32:$dst, (op ADDRri:$addr))]>;
}

multiclass MEMSTORE<string suffix, PatFrag op>  {
	def i : VPInstruction<
		(outs),
		(ins MEMri:$addr, IntRegs:$src),
		!strconcat("mem_", !strconcat(suffix, "[s$addr] = s$src")),
		[(op i32:$src, ADDRri:$addr)]>;

	def f : VPInstruction<
		(outs),
		(ins MEMri:$addr, IntRegs:$src),
		!strconcat("mem_", !strconcat(suffix, "[s$addr] = s$src")),
		[(op f32:$src, ADDRri:$addr)]>;
}

defm LBS : MEMLOAD<"b", "s", sextloadi8>;
defm LBU : MEMLOAD<"b", "u", zextloadi8>;
defm LSS : MEMLOAD<"s", "s", sextloadi16>;
defm LSU : MEMLOAD<"s", "u", zextloadi16>;
defm LW : MEMLOAD<"s", "s", load>;
defm SB : MEMSTORE<"b", truncstorei8>;
defm SS : MEMSTORE<"s", truncstorei16>;
defm SW : MEMSTORE<"l", store>;

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBUi ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSSi ADDRri:$src)>;

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

def LO10 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((unsigned)N->getZExtValue() & 1023,
                                   MVT::i32);
}]>;

def HI22 : SDNodeXForm<imm, [{
  // Transformation function: shift the immediate value down into the low bits.
  return CurDAG->getTargetConstant((unsigned)N->getZExtValue() >> 10, MVT::i32);
}]>;

// Branch targets have OtherVT type.
def calltarget : Operand<i32>;

// Operand for printing out a condition code.
let PrintMethod = "printCCOperand" in
  def CCOp : Operand<i32>;

def SDTSPcmpfcc : 
SDTypeProfile<0, 2, [SDTCisFP<0>, SDTCisSameAs<0, 1>]>;
def SDTSPbrcc : 
SDTypeProfile<0, 2, [SDTCisVT<0, OtherVT>, SDTCisVT<1, i32>]>;
def SDTSPselectcc :
SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>, SDTCisSameAs<1, 2>, SDTCisVT<3, i32>]>;

def SPlo    : SDNode<"SPISD::Lo", SDTIntUnaryOp>;


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

def SDT_SPRet     : SDTypeProfile<0, 1, [SDTCisVT<0, i32>]>;
def retflag       : SDNode<"SPISD::RET_FLAG", SDT_SPRet,
                           [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

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

// GETPCX for PIC
let Defs = [O7] in {
  def GETPCX : Pseudo<(outs getPCX:$getpcseq), (ins), "$getpcseq", [] >;
}

let Defs = [O6], Uses = [O6] in {
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


let isReturn = 1, isTerminator = 1, hasDelaySlot = 1 in {
  let rd = 0, rs1 = 0 in
    def RETL: F3_2<2, 0b111000, (outs), (ins i32imm:$val),
                   "jmp %o7+$val", [(retflag simm13:$val)]>;

  let rd = 0, rs1 = 0 in
    def RET: F3_2<2, 0b111000, (outs), (ins i32imm:$val),
                  "jmp %i7+$val", []>;
}




def LEA_ADDri   : F3_2<2, 0b000000,
                   (outs IntRegs:$dst), (ins MEMri:$addr),
                   "$dst = ${addr:arith}",
                   [(set i32:$dst, ADDRri:$addr)]>;

let Uses = [O6],
    hasDelaySlot = 1, isCall = 1,
    Defs = [O0, O1, O2, O3, O4, O5, O7, G1, G2, G3, G4, G5, G6, G7,
        ICC, FCC, Y] in {
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

def : Pat<(i32 simm13:$val),
          (ORri (i32 G0), imm:$val)>;

// Global addresses, constant pool entries
def : Pat<(SPlo tglobaladdr:$in), (ORri (i32 G0), tglobaladdr:$in)>;
def : Pat<(SPlo tconstpool:$in), (ORri (i32 G0), tconstpool:$in)>;

// Add reg, lo.  This is used when taking the addr of a global/constpool entry.
def : Pat<(add i32:$r, (SPlo tglobaladdr:$in)),
          (ADDIri $r, tglobaladdr:$in)>;
def : Pat<(add i32:$r, (SPlo tconstpool:$in)),
          (ADDIri $r, tconstpool:$in)>;

// Calls: 
def : Pat<(call tglobaladdr:$dst),
          (CALL tglobaladdr:$dst)>;
def : Pat<(call texternalsym:$dst),
          (CALL texternalsym:$dst)>;

