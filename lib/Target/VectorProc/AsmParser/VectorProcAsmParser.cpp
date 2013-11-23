//===-- VectorProcAsmParser.cpp - Parse VectorProc assembly to MCInst instructions ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/VectorProcMCTargetDesc.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/MC/MCParser/MCAsmLexer.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCTargetAsmParser.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/Debug.h"
using namespace llvm;

namespace {
struct VectorProcOperand;

class VectorProcAsmParser : public MCTargetAsmParser {
  MCAsmParser &Parser;
  MCAsmParser &getParser() const { return Parser; }
  MCAsmLexer &getLexer() const { return Parser.getLexer(); }
  MCSubtargetInfo &STI;

  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               SmallVectorImpl<MCParsedAsmOperand*> &Operands,
                               MCStreamer &Out, unsigned &ErrorInfo,
                               bool MatchingInlineAsm);

  bool ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc);

  VectorProcOperand *ParseRegister(unsigned &RegNo);

  VectorProcOperand *ParseImmediate();


  bool ParseInstruction(ParseInstructionInfo &Info, 
				StringRef Name, SMLoc NameLoc,
                SmallVectorImpl<MCParsedAsmOperand*> &Operands);

  bool ParseDirective(AsmToken DirectiveID);
  bool parseDirectiveWord(unsigned Size, SMLoc L);

  bool ParseOperand(SmallVectorImpl<MCParsedAsmOperand*> &Operands);
  bool ParseMemoryOperands(SmallVectorImpl<MCParsedAsmOperand*> &Operands, bool hasMask);

  // Auto-generated instruction matching functions
#define GET_ASSEMBLER_HEADER
#include "VectorProcGenAsmMatcher.inc"

public:
  VectorProcAsmParser(MCSubtargetInfo &sti, MCAsmParser &_Parser,
	  const MCInstrInfo &MII)
    : MCTargetAsmParser(), Parser(_Parser), STI(sti) {
      setAvailableFeatures(ComputeAvailableFeatures(STI.getFeatureBits()));
  }

};

/// VectorProcOperand - Instances of this class represented a parsed machine
/// instruction
struct VectorProcOperand : public MCParsedAsmOperand {

  enum KindTy {
    Token,
    Register,
    Immediate,
    Memory
  } Kind;

  SMLoc StartLoc, EndLoc;

  union {
    struct {
      const char *Data;
      unsigned Length;
    } Tok;
    struct {
      unsigned RegNum;
    } Reg;
    struct {
      const MCExpr *Val;
    } Imm;
    struct {
      unsigned BaseReg;
      const MCExpr *Off;
    } Mem;
  };

  VectorProcOperand(KindTy K) : MCParsedAsmOperand(), Kind(K) {}
public:
  VectorProcOperand(const VectorProcOperand &o) : MCParsedAsmOperand() {
    Kind = o.Kind;
    StartLoc = o.StartLoc;
    EndLoc = o.EndLoc;
    switch (Kind) {
      case Register:
        Reg = o.Reg;
        break;
      case Immediate:
        Imm = o.Imm;
        break;
      case Token:
        Tok = o.Tok;
        break;
      case Memory:
        Mem = o.Mem;
        break;
    }
  }

  /// getStartLoc - Gets location of the first token of this operand
  SMLoc getStartLoc() const { return StartLoc; }

  /// getEndLoc - Gets location of the last token of this operand
  SMLoc getEndLoc() const { return EndLoc; }

  unsigned getReg() const {
    assert(Kind == Register && "Invalid type access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert (Kind == Immediate && "Invalid type access!");
    return Imm.Val;
  }

  StringRef getToken() const {
    assert (Kind == Token && "Invalid type access!");
    return StringRef(Tok.Data, Tok.Length);
  }

  // Functions for testing operand type
  bool isReg() const { return Kind == Register; }
  bool isImm() const { return Kind == Immediate; }
  bool isToken() const { return Kind == Token; }
  bool isMem() const { return Kind == Memory; }

  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    // Add as immediates where possible. Null MCExpr = 0
    if (Expr == 0)
      Inst.addOperand(MCOperand::CreateImm(0));
    else if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::CreateImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::CreateExpr(Expr));
  }

  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::CreateReg(getReg()));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  // FIXME: Implement this
  void print(raw_ostream &OS) const {}


  static VectorProcOperand *CreateToken(StringRef Str, SMLoc S) {
    VectorProcOperand *Op = new VectorProcOperand(Token);
    Op->Tok.Data = Str.data();
    Op->Tok.Length = Str.size();
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static VectorProcOperand *CreateReg(unsigned RegNo, SMLoc S, SMLoc E) {
    VectorProcOperand *Op = new VectorProcOperand(Register);
    Op->Reg.RegNum = RegNo;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }
  
  static VectorProcOperand *CreateImm(const MCExpr *Val, SMLoc S, SMLoc E) {
    VectorProcOperand *Op = new VectorProcOperand(Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }
};
} // end anonymous namespace.

// Auto-generated by TableGen
static unsigned MatchRegisterName(StringRef Name);

bool VectorProcAsmParser::
MatchAndEmitInstruction(SMLoc IDLoc,
						unsigned &Opcode,
                        SmallVectorImpl<MCParsedAsmOperand*> &Operands,
                        MCStreamer &Out, 
                        unsigned &ErrorInfo,
                        bool MatchingInlineAsm) {
  MCInst Inst;
  SMLoc ErrorLoc;
  SmallVector<std::pair< unsigned, std::string >, 4> MapAndConstraints;

  switch (MatchInstructionImpl(Operands, Inst, ErrorInfo, MatchingInlineAsm)) {
    default: break;
    case Match_Success:
      Out.EmitInstruction(Inst);
      return false;
    case Match_MissingFeature:
      return Error(IDLoc, "Instruction use requires option to be enabled");
    case Match_MnemonicFail:
      return Error(IDLoc, "Unrecognized instruction mnemonic");
    case Match_InvalidOperand:
      ErrorLoc = IDLoc;
      if (ErrorInfo != ~0U) {
        if (ErrorInfo >= Operands.size())
          return Error(IDLoc, "Too few operands for instruction");

        ErrorLoc = ((VectorProcOperand*)Operands[ErrorInfo])->getStartLoc();
        if (ErrorLoc == SMLoc())
          ErrorLoc = IDLoc;
      }

      return Error(IDLoc, "Invalid operand for instruction");
  }

  llvm_unreachable("Unknown match type detected!");
}

bool VectorProcAsmParser::
ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc) {
  return (ParseRegister(RegNo) == 0);
}

VectorProcOperand *VectorProcAsmParser::ParseRegister(unsigned &RegNo) {
  SMLoc S = Parser.getTok().getLoc();
  SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() -1);

  switch(getLexer().getKind()) {
    default: return 0;
    case AsmToken::Identifier:
      RegNo = MatchRegisterName(getLexer().getTok().getIdentifier());
      if (RegNo == 0)
        return 0;
      getLexer().Lex();
      return VectorProcOperand::CreateReg(RegNo, S, E);
  }
  return 0;
}

VectorProcOperand *VectorProcAsmParser::ParseImmediate() {
  SMLoc S = Parser.getTok().getLoc();
  SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() -1);

  const MCExpr *EVal;
  switch(getLexer().getKind()) {
    default: return 0;
    case AsmToken::Plus:
    case AsmToken::Minus:
    case AsmToken::Integer:
      if(getParser().parseExpression(EVal))
        return 0;

      int64_t ans;
      EVal->EvaluateAsAbsolute(ans);
      return VectorProcOperand::CreateImm(EVal, S, E);
  }
}

bool VectorProcAsmParser::
ParseOperand(SmallVectorImpl<MCParsedAsmOperand*> &Operands) 
{
	VectorProcOperand *Op;
	unsigned RegNo;

	// Attempt to parse token as register
	Op = ParseRegister(RegNo);
	if (Op)
	{
		Operands.push_back(Op);
		return false;
	}  	
  
	Op = ParseImmediate();
	if (Op)
	{
		// Just an immediate
		Operands.push_back(Op);
		return false;
	}

	// Identifier
	const MCExpr *IdVal;
	SMLoc S = Parser.getTok().getLoc();
	if (!getParser().parseExpression(IdVal))
	{
		SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
		Op = VectorProcOperand::CreateImm(IdVal, S, E);
		Operands.push_back(Op);
		return false;
	}

	// Error
	Error(Parser.getTok().getLoc(), "unknown operand");
	return true;
}

bool VectorProcAsmParser::
ParseMemoryOperands(SmallVectorImpl<MCParsedAsmOperand*> &Operands, bool hasMask) 
{
	VectorProcOperand *MaskOp = 0;
	if (hasMask)
	{
		unsigned RegNo;
		MaskOp = ParseRegister(RegNo);
		if (getLexer().isNot(AsmToken::Comma))
		{
			Error(Parser.getTok().getLoc(), "missing ,");
			return true;
		}

		getLexer().Lex();
		Operands.push_back(MaskOp);
	}

	if (getLexer().is(AsmToken::Identifier))
	{
		// PC relative memory label memory access
		// load.32 s0, aLabel

		const MCExpr *IdVal;
		SMLoc S = Parser.getTok().getLoc();
		if (getParser().parseExpression(IdVal))
			return true;	// Bad identifier
			
		SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);

		// This will be turned into a PC relative load.  First push the
		// PC register (31), then add the identifier, which will be fixed up
		// later
		Operands.push_back(VectorProcOperand::CreateReg(MatchRegisterName("pc"), S, E));
		Operands.push_back(VectorProcOperand::CreateImm(IdVal, S, E));
		return false;
	}

	VectorProcOperand *OffsetOp;
	if (getLexer().is(AsmToken::Integer))
		OffsetOp = ParseImmediate();	// There is an offset 
	else
		OffsetOp = VectorProcOperand::CreateImm(0, Parser.getTok().getLoc(), Parser.getTok().getLoc()); 
			// Offset is zero

  	if (!getLexer().is(AsmToken::LParen)) 
  	{
		Error(Parser.getTok().getLoc(), "bad memory operand, missing (");
		return true;
	}

	getLexer().Lex();
	unsigned RegNo;
	VectorProcOperand *RegOp = ParseRegister(RegNo);
	if (!RegOp)
	{
		Error(Parser.getTok().getLoc(), "bad memory operand: invalid register");
		return true;
	}

	if (getLexer().isNot(AsmToken::RParen)) 
	{
		Error(Parser.getTok().getLoc(), "bad memory operand, missing (");
		return true;
	}

	getLexer().Lex();

	Operands.push_back(RegOp);
	Operands.push_back(OffsetOp);

	return false;
}

bool VectorProcAsmParser::
ParseInstruction(ParseInstructionInfo &Info, 
				StringRef Name, SMLoc NameLoc,
                SmallVectorImpl<MCParsedAsmOperand*> &Operands) 
{
	size_t dotLoc = Name.find('.');
	StringRef stem = Name.substr(0,dotLoc);
	Operands.push_back(VectorProcOperand::CreateToken(stem,NameLoc));
	if (dotLoc < Name.size()) {
		size_t dotLoc2 = Name.rfind('.');
		if (dotLoc == dotLoc2)
			Operands.push_back(VectorProcOperand::CreateToken(Name.substr(dotLoc),NameLoc));
		else {
			Operands.push_back(VectorProcOperand::CreateToken(Name.substr
				(dotLoc, dotLoc2-dotLoc), NameLoc));
			Operands.push_back(VectorProcOperand::CreateToken(Name.substr
				(dotLoc2), NameLoc));
		}
	}

	// If there are no more operands, then finish
	if (getLexer().is(AsmToken::EndOfStatement))
		return false;

	// Parse first operand (usually the destination of the instruction)
	if (ParseOperand(Operands))
		return true;

	if (stem == "load" || stem == "store")
	{
		if (getLexer().is(AsmToken::EndOfStatement) 
			|| getLexer().isNot(AsmToken::Comma)) 
		{
			Error(Parser.getTok().getLoc(), "bad memory operand, missing ,");
			return true;	
		}

		getLexer().Lex(); // Consume comma token

		bool hasMask = Name.find(".mask") != StringRef::npos;
		if (ParseMemoryOperands(Operands, hasMask))
			return true;
	}
	else
	{
		// Parse until end of statement, consuming commas between operands
		while (getLexer().isNot(AsmToken::EndOfStatement) 
			&& getLexer().is(AsmToken::Comma)) 
		{
			// Consume comma token
			getLexer().Lex();

			// Parse next operand
			if (ParseOperand(Operands))
				return true;
		}
	}

	return false;
}

/// parseDirectiveWord
///  ::= .word [ expression (, expression)* ]
bool VectorProcAsmParser::parseDirectiveWord(unsigned Size, SMLoc L) {
  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    for (;;) {
      const MCExpr *Value;
      if (getParser().parseExpression(Value))
        return true;

      getParser().getStreamer().EmitValue(Value, Size);

      if (getLexer().is(AsmToken::EndOfStatement))
        break;

      if (getLexer().isNot(AsmToken::Comma))
        return Error(L, "unexpected token in directive");

      Parser.Lex();
    }
  }

  Parser.Lex();
  return false;
}

bool VectorProcAsmParser::
ParseDirective(AsmToken DirectiveID) {
  StringRef IDVal = DirectiveID.getString();
  if (IDVal == ".word") {
    parseDirectiveWord(4, DirectiveID.getLoc());
    return false;
  }

  return true;
}

extern "C" void LLVMInitializeVectorProcAsmParser() {
  RegisterMCAsmParser<VectorProcAsmParser> X(TheVectorProcTarget);
}

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#include "VectorProcGenAsmMatcher.inc"
