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

def ADDRrr : ComplexPattern<iPTR, 2, "SelectADDRrr", [], []>;
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
		(outs FPRegs:$dst), 
		(ins FPRegs:$b, FPRegs:$c),
		!strconcat("f$dst = f$b ", !strconcat(operator, " f$c")),
		[(set f32:$dst, (OpNode f32:$b, f32:$c))]>;

defm AND    : VPTernaryIntArith<"&", and>;
defm OR     : VPTernaryIntArith<"|", or>;
defm XOR    : VPTernaryIntArith<"^", xor>;
defm SLL    : VPTernaryIntArith<"<<", shl>;
defm SRL    : VPTernaryIntArith<">>", srl>;
defm SRA    : VPTernaryIntArith<">>", sra>;	// XXX need to use U register.
defm ADDI   : VPTernaryIntArith<"+", add>;
defm SUBI   : VPTernaryIntArith<"-", add>;
//def ADDF    : VPTernaryFloatArith<"+", add>;
//def SUBF    : VPTernaryFloatArith<"-", add>;
//def MULF    : VPTernaryFloatArith<"*", mul>;

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
		(ins FPRegs:$a, FPRegs:$b),
		!strconcat("s$dst = f$a ", !strconcat(operator, " f$b")),
		[(set i32:$dst, (selectcc f32:$a, f32:$b, 1, 0, condition))]>
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

class MEMLOAD<string suffix, string regtype, PatFrag op> : VPInstruction<
	(outs IntRegs:$dst),
	(ins MEMri:$addr),
	!strconcat(!strconcat(!strconcat(suffix, "$dst = mem_"), regtype), "[s$addr]"),
	[(set i32:$dst, (op ADDRri:$addr))]>
{
}

class MEMSTORE<string suffix, PatFrag op> : VPInstruction<
	(outs),
	(ins MEMri:$addr, IntRegs:$src),
	!strconcat("mem_", !strconcat(suffix, "[s$addr] = s$src")),
	[(op i32:$src, ADDRri:$addr)]>
{
}

def LBS : MEMLOAD<"b", "s", sextloadi8>;
def LBU : MEMLOAD<"b", "u", zextloadi8>;
def LSS : MEMLOAD<"s", "s", sextloadi16>;
def LSU : MEMLOAD<"s", "u", zextloadi16>;
def LW : MEMLOAD<"s", "s", load>;
def SB : MEMSTORE<"b", truncstorei8>;
def SS : MEMSTORE<"s", truncstorei16>;
def SW : MEMSTORE<"l", store>;

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LBU ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LBU ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LSS ADDRri:$src)>;

class F2<dag outs, dag ins, string asmstr, list<dag> pattern>
   : VPInstruction<outs, ins, asmstr, pattern> {
  bits<3>  op2;
  bits<22> imm22;
}

class F2_1<bits<3> op2Val, dag outs, dag ins, string asmstr, list<dag> pattern>
   : F2<outs, ins, asmstr, pattern> {
  bits<5>  rd;

}

class F2_2<bits<4> condVal, bits<3> op2Val, dag outs, dag ins, string asmstr, 
           list<dag> pattern> : F2<outs, ins, asmstr, pattern> {
  bits<4>   cond;
  bit       annul = 0;     // currently unused

  let cond        = condVal;
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

// floating-point
class F3_3<bits<2> opVal, bits<6> op3val, bits<9> opfval, dag outs, dag ins,
           string asmstr, list<dag> pattern> : F3<outs, ins, asmstr, pattern> {
  bits<5> rs2;

 
}

// Shift by register rs2.
class F3_Sr<bits<2> opVal, bits<6> op3val, bit xVal, dag outs, dag ins,
            string asmstr, list<dag> pattern> : F3<outs, ins, asmstr, pattern> {
  bit x = xVal;           // 1 for 64-bit shifts.
  bits<5> rs2;
}

// Shift by immediate.
class F3_Si<bits<2> opVal, bits<6> op3val, bit xVal, dag outs, dag ins,
            string asmstr, list<dag> pattern> : F3<outs, ins, asmstr, pattern> {
  bit x = xVal;           // 1 for 64-bit shifts.
  bits<6> shcnt;          // shcnt32 / shcnt64.
}

// Define rr and ri shift instructions with patterns.
multiclass F3_S<string OpcStr, bits<6> Op3Val, bit XVal, SDNode OpNode,
                ValueType VT, RegisterClass RC> {
  def rr : F3_Sr<2, Op3Val, XVal, (outs RC:$rd), (ins RC:$rs, RC:$rs2),
                 !strconcat(OpcStr, " $rs, $rs2, $rd"),
                 [(set VT:$rd, (OpNode VT:$rs, VT:$rs2))]>;
  def ri : F3_Si<2, Op3Val, XVal, (outs RC:$rd), (ins RC:$rs, unknown:$shcnt),
                 !strconcat(OpcStr, " $rs, $shcnt, $rd"),
                 [(set VT:$rd, (OpNode VT:$rs, (VT imm:$shcnt)))]>;
}


def LO10 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant((unsigned)N->getZExtValue() & 1023,
                                   MVT::i32);
}]>;

def HI22 : SDNodeXForm<imm, [{
  // Transformation function: shift the immediate value down into the low bits.
  return CurDAG->getTargetConstant((unsigned)N->getZExtValue() >> 10, MVT::i32);
}]>;

// Address operands
def MEMrr : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, ptr_rc);
}

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
def SDTSPFTOI :
SDTypeProfile<1, 1, [SDTCisVT<0, f32>, SDTCisFP<1>]>;
def SDTSPITOF :
SDTypeProfile<1, 1, [SDTCisFP<0>, SDTCisVT<1, f32>]>;

def SPcmpicc : SDNode<"SPISD::CMPICC", SDTIntBinOp, [SDNPOutGlue]>;
def SPcmpfcc : SDNode<"SPISD::CMPFCC", SDTSPcmpfcc, [SDNPOutGlue]>;
def SPbricc : SDNode<"SPISD::BRICC", SDTSPbrcc, [SDNPHasChain, SDNPInGlue]>;
def SPbrxcc : SDNode<"SPISD::BRXCC", SDTSPbrcc, [SDNPHasChain, SDNPInGlue]>;
def SPbrfcc : SDNode<"SPISD::BRFCC", SDTSPbrcc, [SDNPHasChain, SDNPInGlue]>;

def SPhi    : SDNode<"SPISD::Hi", SDTIntUnaryOp>;
def SPlo    : SDNode<"SPISD::Lo", SDTIntUnaryOp>;

def SPftoi  : SDNode<"SPISD::FTOI", SDTSPFTOI>;
def SPitof  : SDNode<"SPISD::ITOF", SDTSPITOF>;

def SPselecticc : SDNode<"SPISD::SELECT_ICC", SDTSPselectcc, [SDNPInGlue]>;
def SPselectxcc : SDNode<"SPISD::SELECT_XCC", SDTSPselectcc, [SDNPInGlue]>;
def SPselectfcc : SDNode<"SPISD::SELECT_FCC", SDTSPselectcc, [SDNPInGlue]>;

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


let isReturn = 1, isTerminator = 1, hasDelaySlot = 1, isBarrier = 1 in {
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

let Defs = [Y] in {
  defm SMUL : VPTernaryIntArith  <"*", mul>;
}


let Uses = [O6],
    hasDelaySlot = 1, isCall = 1,
    Defs = [O0, O1, O2, O3, O4, O5, O7, G1, G2, G3, G4, G5, G6, G7,
        ICC, FCC, Y] in {
  def CALL : VPInstruction<(outs), (ins calltarget:$dst, variable_ops),
                    "call $dst", []> {
    bits<30> disp;
  }
  
  // indirect calls
  def JMPLrr : F3_1<2, 0b111000,
                    (outs), (ins MEMrr:$ptr, variable_ops),
                    "call $ptr",
                    [(call ADDRrr:$ptr)]>;
  def JMPLri : F3_2<2, 0b111000,
                    (outs), (ins MEMri:$ptr, variable_ops),
                    "call $ptr",
                    [(call ADDRri:$ptr)]>;
}


def FITOS : F3_3<2, 0b110100, 0b011000100,
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fitos $src, $dst",
                 [(set FPRegs:$dst, (SPitof FPRegs:$src))]>;

// Convert Floating-point to Integer Instructions, p. 142
def FSTOI : F3_3<2, 0b110100, 0b011010001,
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fstoi $src, $dst",
                 [(set FPRegs:$dst, (SPftoi FPRegs:$src))]>;


// Floating-point Move Instructions, p. 144
def FMOVS : F3_3<2, 0b110100, 0b000000001,
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fmovs $src, $dst", []>;
def FNEGS : F3_3<2, 0b110100, 0b000000101, 
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fnegs $src, $dst",
                 [(set f32:$dst, (fneg f32:$src))]>;
def FABSS : F3_3<2, 0b110100, 0b000001001, 
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fabss $src, $dst",
                 [(set f32:$dst, (fabs f32:$src))]>;






// Floating-point Add and Subtract Instructions, p. 146
def FADDS  : F3_3<2, 0b110100, 0b001000001,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "f$dst = f$src1 + f$src2",
                  [(set f32:$dst, (fadd f32:$src1, f32:$src2))]>;
def FSUBS  : F3_3<2, 0b110100, 0b001000101,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "fsubs $src1, $src2, $dst",
                  [(set f32:$dst, (fsub f32:$src1, f32:$src2))]>;

// Floating-point Multiply and Divide Instructions, p. 147
def FMULS  : F3_3<2, 0b110100, 0b001001001,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "fmuls $src1, $src2, $dst",
                  [(set f32:$dst, (fmul f32:$src1, f32:$src2))]>;
def FDIVS  : F3_3<2, 0b110100, 0b001001101,
                 (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                 "fdivs $src1, $src2, $dst",
                 [(set f32:$dst, (fdiv f32:$src1, f32:$src2))]>;


// POPCrr - This does a ctpop of a 64-bit register.  As such, we have to clear
// the top 32-bits before using it.  To do this clearing, we use a SLLri X,0.
def POPCrr : F3_1<2, 0b101110, 
                  (outs IntRegs:$dst), (ins IntRegs:$src),
                  "popc $src, $dst", []>, Requires<[]>;
def : Pat<(ctpop i32:$src),
          (POPCrr (SLLri $src, 0))>;

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

