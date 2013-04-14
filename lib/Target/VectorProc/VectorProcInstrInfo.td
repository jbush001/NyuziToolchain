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
		!strconcat("s$dst = s$b", !strconcat(operator, " s$c")),
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;

	// Instruction format B
	def ri : VPInstruction<
		(outs IntRegs:$dst), 
		(ins IntRegs:$b, i32imm:$c),
		!strconcat("s$dst = s$b", !strconcat(operator, " s$c")),
		[(set i32:$dst, (OpNode i32:$b, i32:$c))]>;	// XXXX simm13
}


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

def SETHIimm : PatLeaf<(imm), [{
  return (((unsigned)N->getZExtValue() >> 10) << 10) ==
         (unsigned)N->getZExtValue();
}], HI22>;

// Addressing modes.

// Address operands
def MEMrr : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, ptr_rc);
}
def MEMri : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops ptr_rc, i32imm);
}

// Branch targets have OtherVT type.
def brtarget : Operand<OtherVT>;
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
// VECTORPROC Flag Conditions
//===----------------------------------------------------------------------===//

// Note that these values must be kept in sync with the CCOp::CondCode enum
// values.
class ICC_VAL<int N> : PatLeaf<(i32 N)>;
def ICC_NE  : ICC_VAL< 9>;  // Not Equal
def ICC_E   : ICC_VAL< 1>;  // Equal
def ICC_G   : ICC_VAL<10>;  // Greater
def ICC_LE  : ICC_VAL< 2>;  // Less or Equal
def ICC_GE  : ICC_VAL<11>;  // Greater or Equal
def ICC_L   : ICC_VAL< 3>;  // Less
def ICC_GU  : ICC_VAL<12>;  // Greater Unsigned
def ICC_LEU : ICC_VAL< 4>;  // Less or Equal Unsigned
def ICC_CC  : ICC_VAL<13>;  // Carry Clear/Great or Equal Unsigned
def ICC_CS  : ICC_VAL< 5>;  // Carry Set/Less Unsigned
def ICC_POS : ICC_VAL<14>;  // Positive
def ICC_NEG : ICC_VAL< 6>;  // Negative
def ICC_VC  : ICC_VAL<15>;  // Overflow Clear
def ICC_VS  : ICC_VAL< 7>;  // Overflow Set

class FCC_VAL<int N> : PatLeaf<(i32 N)>;
def FCC_U   : FCC_VAL<23>;  // Unordered
def FCC_G   : FCC_VAL<22>;  // Greater
def FCC_UG  : FCC_VAL<21>;  // Unordered or Greater
def FCC_L   : FCC_VAL<20>;  // Less
def FCC_UL  : FCC_VAL<19>;  // Unordered or Less
def FCC_LG  : FCC_VAL<18>;  // Less or Greater
def FCC_NE  : FCC_VAL<17>;  // Not Equal
def FCC_E   : FCC_VAL<25>;  // Equal
def FCC_UE  : FCC_VAL<24>;  // Unordered or Equal
def FCC_GE  : FCC_VAL<25>;  // Greater or Equal
def FCC_UGE : FCC_VAL<26>;  // Unordered or Greater or Equal
def FCC_LE  : FCC_VAL<27>;  // Less or Equal
def FCC_ULE : FCC_VAL<28>;  // Unordered or Less or Equal
def FCC_O   : FCC_VAL<29>;  // Ordered
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

def FpMOVD : Pseudo<(outs DFPRegs:$dst), (ins DFPRegs:$src),
				  "!FpMOVD $src, $dst", []>;
def FpNEGD : Pseudo<(outs DFPRegs:$dst), (ins DFPRegs:$src),
				  "!FpNEGD $src, $dst",
				  [(set f64:$dst, (fneg f64:$src))]>;
def FpABSD : Pseudo<(outs DFPRegs:$dst), (ins DFPRegs:$src),
				  "!FpABSD $src, $dst",
				  [(set f64:$dst, (fabs f64:$src))]>;

// SELECT_CC_* - Used to implement the SELECT_CC DAG operation.  Expanded after
// instruction selection into a branch sequence.  This has to handle all
// permutations of selection between i32/f32/f64 on ICC and FCC.
  // Expanded after instruction selection.
let Uses = [ICC], usesCustomInserter = 1 in { 
  def SELECT_CC_Int_ICC
   : Pseudo<(outs IntRegs:$dst), (ins IntRegs:$T, IntRegs:$F, i32imm:$Cond),
            "; SELECT_CC_Int_ICC PSEUDO!",
            [(set i32:$dst, (SPselecticc i32:$T, i32:$F, imm:$Cond))]>;
  def SELECT_CC_FP_ICC
   : Pseudo<(outs FPRegs:$dst), (ins FPRegs:$T, FPRegs:$F, i32imm:$Cond),
            "; SELECT_CC_FP_ICC PSEUDO!",
            [(set f32:$dst, (SPselecticc f32:$T, f32:$F, imm:$Cond))]>;

  def SELECT_CC_DFP_ICC
   : Pseudo<(outs DFPRegs:$dst), (ins DFPRegs:$T, DFPRegs:$F, i32imm:$Cond),
            "; SELECT_CC_DFP_ICC PSEUDO!",
            [(set f64:$dst, (SPselecticc f64:$T, f64:$F, imm:$Cond))]>;
}

let usesCustomInserter = 1, Uses = [FCC] in {

  def SELECT_CC_Int_FCC
   : Pseudo<(outs IntRegs:$dst), (ins IntRegs:$T, IntRegs:$F, i32imm:$Cond),
            "; SELECT_CC_Int_FCC PSEUDO!",
            [(set i32:$dst, (SPselectfcc i32:$T, i32:$F, imm:$Cond))]>;

  def SELECT_CC_FP_FCC
   : Pseudo<(outs FPRegs:$dst), (ins FPRegs:$T, FPRegs:$F, i32imm:$Cond),
            "; SELECT_CC_FP_FCC PSEUDO!",
            [(set f32:$dst, (SPselectfcc f32:$T, f32:$F, imm:$Cond))]>;
  def SELECT_CC_DFP_FCC
   : Pseudo<(outs DFPRegs:$dst), (ins DFPRegs:$T, DFPRegs:$F, i32imm:$Cond),
            "; SELECT_CC_DFP_FCC PSEUDO!",
            [(set f64:$dst, (SPselectfcc f64:$T, f64:$F, imm:$Cond))]>;
}


// Section A.3 - Synthetic Instructions, p. 85
// special cases of JMPL:
let isReturn = 1, isTerminator = 1, hasDelaySlot = 1, isBarrier = 1 in {
  let rd = O7.Num, rs1 = G0.Num in
    def RETL: F3_2<2, 0b111000, (outs), (ins i32imm:$val),
                   "jmp %o7+$val", [(retflag simm13:$val)]>;

  let rd = I7.Num, rs1 = G0.Num in
    def RET: F3_2<2, 0b111000, (outs), (ins i32imm:$val),
                  "jmp %i7+$val", []>;
}

def LDSBri : F3_2<3, 0b001001,
                  (outs IntRegs:$dst), (ins MEMri:$addr),
                  "s$dst = mem_b[s$addr]",
                  [(set i32:$dst, (sextloadi8 ADDRri:$addr))]>;
def LDSHri : F3_2<3, 0b001010,
                  (outs IntRegs:$dst), (ins MEMri:$addr),
                  "s%dst = mem_s[s$addr]",
                  [(set i32:$dst, (sextloadi16 ADDRri:$addr))]>;
def LDUBri : F3_2<3, 0b000001,
                  (outs IntRegs:$dst), (ins MEMri:$addr),
                  "u%dst = mem_s[s$addr]",
                  [(set i32:$dst, (zextloadi8 ADDRri:$addr))]>;
def LDUHri : F3_2<3, 0b000010,
                  (outs IntRegs:$dst), (ins MEMri:$addr),
                  "s%dst = mem_s[s$addr]",
                  [(set i32:$dst, (zextloadi16 ADDRri:$addr))]>;
def LDri   : F3_2<3, 0b000000,
                  (outs IntRegs:$dst), (ins MEMri:$addr),
                  "s%dst = mem_l[s$addr]",
                  [(set i32:$dst, (load ADDRri:$addr))]>;

def LDFri  : F3_2<3, 0b100000,
                  (outs FPRegs:$dst), (ins MEMri:$addr),
                  "s%dst = mem_l[s$addr]",
                  [(set f32:$dst, (load ADDRri:$addr))]>;
def LDDFri : F3_2<3, 0b100011,
                  (outs DFPRegs:$dst), (ins MEMri:$addr),
                  "s%dst = mem_l[s$addr]",
                  [(set f64:$dst, (load ADDRri:$addr))]>;

def STBri : F3_2<3, 0b000101,
                 (outs), (ins MEMri:$addr, IntRegs:$src),
                 "mem_b[s$addr] = s$src",
                 [(truncstorei8 i32:$src, ADDRri:$addr)]>;
def STHri : F3_2<3, 0b000110,
                 (outs), (ins MEMri:$addr, IntRegs:$src),
                 "mem_s[s$addr] = s$src",
                 [(truncstorei16 i32:$src, ADDRri:$addr)]>;
def STri  : F3_2<3, 0b000100,
                 (outs), (ins MEMri:$addr, IntRegs:$src),
                 "mem_l[s$addr] = s$src",
                 [(store i32:$src, ADDRri:$addr)]>;

def STFri   : F3_2<3, 0b100100,
                   (outs), (ins MEMri:$addr, FPRegs:$src),
                   "mem_l[s$addr] = s$src",
                   [(store f32:$src, ADDRri:$addr)]>;
def STDFri  : F3_2<3, 0b100111,
                   (outs), (ins MEMri:$addr, DFPRegs:$src),
                   "mem_l[s$addr] = s$src",
                   [(store f64:$src, ADDRri:$addr)]>;

def SETHIi: F2_1<0b100,
                 (outs IntRegs:$dst), (ins i32imm:$src),
                 "sethi $src, $dst",
                 [(set i32:$dst, SETHIimm:$src)]>;

// Section B.10 - NOP Instruction, p. 105
// (It's a special case of SETHI)
let rd = 0, imm22 = 0 in
  def NOP : F2_1<0b100, (outs), (ins), "nop", []>;

defm AND    : VPTernaryIntArith<"&", and>;
defm OR     : VPTernaryIntArith<"|", or>;
defm XOR    : VPTernaryIntArith<"^", xor>;
defm SLL    : VPTernaryIntArith<"<<", shl>;
defm SRL    : VPTernaryIntArith<">>", srl>;
defm SRA    : VPTernaryIntArith<">>", sra>;	// XXX need to use U register.
defm ADD    : VPTernaryIntArith<"+", add>;

def LEA_ADDri   : F3_2<2, 0b000000,
                   (outs IntRegs:$dst), (ins MEMri:$addr),
                   "$dst = ${addr:arith}",
                   [(set i32:$dst, ADDRri:$addr)]>;

let Defs = [Y] in {
  defm SMUL : VPTernaryIntArith  <"*", mul>;
}

def BranchIfTrue : VPInstruction<
	(outs),
	(ins IntRegs:$test, brtarget:$dst),
	"if $test goto $dst",
	[(brcond i32:$test, bb:$dst)]>;

// conditional branch class:
class BranchSP<bits<4> cc, dag ins, string asmstr, list<dag> pattern>
 : F2_2<cc, 0b010, (outs), ins, asmstr, pattern> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
}

let isBarrier = 1 in
  def BA   : BranchSP<0b1000, (ins brtarget:$dst),
                      "ba $dst",
                      [(br bb:$dst)]>;

// FIXME: the encoding for the JIT should look at the condition field.
let Uses = [ICC] in
  def BCOND : BranchSP<0, (ins brtarget:$dst, CCOp:$cc),
                         "b$cc $dst",
                        [(SPbricc bb:$dst, imm:$cc)]>;


// Section B.22 - Branch on Floating-point Condition Codes Instructions, p. 121

// floating-point conditional branch class:
class FPBranchSP<bits<4> cc, dag ins, string asmstr, list<dag> pattern>
 : F2_2<cc, 0b110, (outs), ins, asmstr, pattern> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
}

// FIXME: the encoding for the JIT should look at the condition field.
let Uses = [FCC] in
  def FBCOND  : FPBranchSP<0, (ins brtarget:$dst, CCOp:$cc),
                              "fb$cc $dst",
                              [(SPbrfcc bb:$dst, imm:$cc)]>;


// Section B.24 - Call and Link Instruction, p. 125
// This is the only Format 1 instruction
let Uses = [O6],
    hasDelaySlot = 1, isCall = 1,
    Defs = [O0, O1, O2, O3, O4, O5, O7, G1, G2, G3, G4, G5, G6, G7,
    D0, D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15,
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

// Section B.28 - Read State Register Instructions
let Uses = [Y] in 
  def RDY : F3_1<2, 0b101000,
                 (outs IntRegs:$dst), (ins),
                 "rd %y, $dst", []>;

// Section B.29 - Write State Register Instructions
let Defs = [Y] in {
  def WRYrr : F3_1<2, 0b110000,
                   (outs), (ins IntRegs:$b, IntRegs:$c),
                   "wr $b, $c, %y", []>;
  def WRYri : F3_2<2, 0b110000,
                   (outs), (ins IntRegs:$b, i32imm:$c),
                   "wr $b, $c, %y", []>;
}
// Convert Integer to Floating-point Instructions, p. 141
def FITOS : F3_3<2, 0b110100, 0b011000100,
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fitos $src, $dst",
                 [(set FPRegs:$dst, (SPitof FPRegs:$src))]>;
def FITOD : F3_3<2, 0b110100, 0b011001000, 
                 (outs DFPRegs:$dst), (ins FPRegs:$src),
                 "fitod $src, $dst",
                 [(set DFPRegs:$dst, (SPitof FPRegs:$src))]>;

// Convert Floating-point to Integer Instructions, p. 142
def FSTOI : F3_3<2, 0b110100, 0b011010001,
                 (outs FPRegs:$dst), (ins FPRegs:$src),
                 "fstoi $src, $dst",
                 [(set FPRegs:$dst, (SPftoi FPRegs:$src))]>;
def FDTOI : F3_3<2, 0b110100, 0b011010010,
                 (outs FPRegs:$dst), (ins DFPRegs:$src),
                 "fdtoi $src, $dst",
                 [(set FPRegs:$dst, (SPftoi DFPRegs:$src))]>;

// Convert between Floating-point Formats Instructions, p. 143
def FSTOD : F3_3<2, 0b110100, 0b011001001, 
                 (outs DFPRegs:$dst), (ins FPRegs:$src),
                 "fstod $src, $dst",
                 [(set f64:$dst, (fextend f32:$src))]>;
def FDTOS : F3_3<2, 0b110100, 0b011000110,
                 (outs FPRegs:$dst), (ins DFPRegs:$src),
                 "fdtos $src, $dst",
                 [(set f32:$dst, (fround f64:$src))]>;

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


// Floating-point Square Root Instructions, p.145
def FSQRTS : F3_3<2, 0b110100, 0b000101001, 
                  (outs FPRegs:$dst), (ins FPRegs:$src),
                  "fsqrts $src, $dst",
                  [(set f32:$dst, (fsqrt f32:$src))]>;
def FSQRTD : F3_3<2, 0b110100, 0b000101010, 
                  (outs DFPRegs:$dst), (ins DFPRegs:$src),
                  "fsqrtd $src, $dst",
                  [(set f64:$dst, (fsqrt f64:$src))]>;



// Floating-point Add and Subtract Instructions, p. 146
def FADDS  : F3_3<2, 0b110100, 0b001000001,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "f$dst = f$src1 + f$src2",
                  [(set f32:$dst, (fadd f32:$src1, f32:$src2))]>;
def FADDD  : F3_3<2, 0b110100, 0b001000010,
                  (outs DFPRegs:$dst), (ins DFPRegs:$src1, DFPRegs:$src2),
                  "faddd $src1, $src2, $dst",
                  [(set f64:$dst, (fadd f64:$src1, f64:$src2))]>;
def FSUBS  : F3_3<2, 0b110100, 0b001000101,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "fsubs $src1, $src2, $dst",
                  [(set f32:$dst, (fsub f32:$src1, f32:$src2))]>;
def FSUBD  : F3_3<2, 0b110100, 0b001000110,
                  (outs DFPRegs:$dst), (ins DFPRegs:$src1, DFPRegs:$src2),
                  "fsubd $src1, $src2, $dst",
                  [(set f64:$dst, (fsub f64:$src1, f64:$src2))]>;

// Floating-point Multiply and Divide Instructions, p. 147
def FMULS  : F3_3<2, 0b110100, 0b001001001,
                  (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "fmuls $src1, $src2, $dst",
                  [(set f32:$dst, (fmul f32:$src1, f32:$src2))]>;
def FMULD  : F3_3<2, 0b110100, 0b001001010,
                  (outs DFPRegs:$dst), (ins DFPRegs:$src1, DFPRegs:$src2),
                  "fmuld $src1, $src2, $dst",
                  [(set f64:$dst, (fmul f64:$src1, f64:$src2))]>;
def FSMULD : F3_3<2, 0b110100, 0b001101001,
                  (outs DFPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                  "fsmuld $src1, $src2, $dst",
                  [(set f64:$dst, (fmul (fextend f32:$src1),
                                        (fextend f32:$src2)))]>;
def FDIVS  : F3_3<2, 0b110100, 0b001001101,
                 (outs FPRegs:$dst), (ins FPRegs:$src1, FPRegs:$src2),
                 "fdivs $src1, $src2, $dst",
                 [(set f32:$dst, (fdiv f32:$src1, f32:$src2))]>;
def FDIVD  : F3_3<2, 0b110100, 0b001001110,
                 (outs DFPRegs:$dst), (ins DFPRegs:$src1, DFPRegs:$src2),
                 "fdivd $src1, $src2, $dst",
                 [(set f64:$dst, (fdiv f64:$src1, f64:$src2))]>;

// Floating-point Compare Instructions, p. 148
// Note: the 2nd template arg is different for these guys.
// Note 2: the result of a FCMP is not available until the 2nd cycle
// after the instr is retired, but there is no interlock. This behavior
// is modelled with a forced noop after the instruction.
let Defs = [FCC] in {
  def FCMPS  : F3_3<2, 0b110101, 0b001010001,
                   (outs), (ins FPRegs:$src1, FPRegs:$src2),
                   "fcmps $src1, $src2\n\tnop",
                   [(SPcmpfcc f32:$src1, f32:$src2)]>;
  def FCMPD  : F3_3<2, 0b110101, 0b001010010,
                   (outs), (ins DFPRegs:$src1, DFPRegs:$src2),
                   "fcmpd $src1, $src2\n\tnop",
                   [(SPcmpfcc f64:$src1, f64:$src2)]>;
}



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

// Small immediates.
def : Pat<(i32 simm13:$val),
          (ORri (i32 G0), imm:$val)>;
// Arbitrary immediates.
def : Pat<(i32 imm:$val),
          (ORri (SETHIi (HI22 imm:$val)), (LO10 imm:$val))>;


// Global addresses, constant pool entries
def : Pat<(SPhi tglobaladdr:$in), (SETHIi tglobaladdr:$in)>;
def : Pat<(SPlo tglobaladdr:$in), (ORri (i32 G0), tglobaladdr:$in)>;
def : Pat<(SPhi tconstpool:$in), (SETHIi tconstpool:$in)>;
def : Pat<(SPlo tconstpool:$in), (ORri (i32 G0), tconstpool:$in)>;

// Add reg, lo.  This is used when taking the addr of a global/constpool entry.
def : Pat<(add i32:$r, (SPlo tglobaladdr:$in)),
          (ADDri $r, tglobaladdr:$in)>;
def : Pat<(add i32:$r, (SPlo tconstpool:$in)),
          (ADDri $r, tconstpool:$in)>;

// Calls: 
def : Pat<(call tglobaladdr:$dst),
          (CALL tglobaladdr:$dst)>;
def : Pat<(call texternalsym:$dst),
          (CALL texternalsym:$dst)>;

def : Pat<(i32 (extloadi1 ADDRri:$src)), (LDUBri ADDRri:$src)>;
def : Pat<(i32 (extloadi8 ADDRri:$src)), (LDUBri ADDRri:$src)>;
def : Pat<(i32 (extloadi16 ADDRri:$src)), (LDUHri ADDRri:$src)>;
def : Pat<(i32 (zextloadi1 ADDRri:$src)), (LDUBri ADDRri:$src)>;
