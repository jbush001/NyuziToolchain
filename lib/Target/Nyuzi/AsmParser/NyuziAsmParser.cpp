//===-- NyuziAsmParser.cpp - Parse Nyuzi assembly to MCInst instructions -===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/NyuziMCExpr.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCParser/MCAsmLexer.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCObjectFileInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

namespace {
struct NyuziOperand;

class NyuziAsmParser : public MCTargetAsmParser {
  MCAsmParser &Parser;
  MCAsmLexer &getLexer() const { return Parser.getLexer(); }

  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;

  bool ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc) override;

  bool ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;

  bool ParseDirective(AsmToken DirectiveID) override;

  bool ParseOperand(OperandVector &Operands, StringRef Name);
  bool ProcessInstruction(MCInst &Inst, const SMLoc &Loc, MCStreamer &Out);

// Auto-generated instruction matching functions
#define GET_ASSEMBLER_HEADER
#include "NyuziGenAsmMatcher.inc"

  OperandMatchResultTy ParseMemoryOperandS10(OperandVector &Operands);
  OperandMatchResultTy ParseMemoryOperandS14(OperandVector &Operands);
  OperandMatchResultTy ParseMemoryOperandS15(OperandVector &Operands);
  OperandMatchResultTy ParseMemoryOperandV10(OperandVector &Operands);
  OperandMatchResultTy ParseMemoryOperandV15(OperandVector &Operands);
  OperandMatchResultTy ParseMemoryOperand(OperandVector &Operands, int MaxBits,
                                          bool OpIsVector);
  OperandMatchResultTy ParseImmediate(OperandVector &Operands, int MaxBits,
                                      bool isSigned);
  OperandMatchResultTy ParseSImm9Value(OperandVector &Operands);
  OperandMatchResultTy ParseSImm14Value(OperandVector &Operands);
  OperandMatchResultTy ParseSImm19Value(OperandVector &Operands);
  OperandMatchResultTy ParseSymbolicOperand(OperandVector &Operands);

public:
  NyuziAsmParser(const MCSubtargetInfo &sti, MCAsmParser &_Parser,
                 const MCInstrInfo &MII, const MCTargetOptions &Options)
      : MCTargetAsmParser(Options, sti, MII), Parser(_Parser) {
    setAvailableFeatures(ComputeAvailableFeatures(sti.getFeatureBits()));
  }
};

/// NyuziOperand - Instances of this class represented a parsed machine
/// instruction
struct NyuziOperand : public MCParsedAsmOperand {

  enum KindTy { K_Token, K_Register, K_Immediate, K_Memory } Kind;

  struct Token {
    const char *Data;
    unsigned Length;
  };

  struct RegisterIndex {
    unsigned RegNum;
  };

  struct ImmediateOperand {
    const MCExpr *Val;
  };

  struct MemoryOperand {
    unsigned BaseReg;
    const MCExpr *Off;
  };

  SMLoc StartLoc, EndLoc;

  union {
    struct Token Tok;
    struct RegisterIndex Reg;
    struct ImmediateOperand Imm;
    struct MemoryOperand Mem;
  };

  explicit NyuziOperand(KindTy K) : MCParsedAsmOperand(), Kind(K) {}

public:
  /// getStartLoc - Gets location of the first token of this operand
  SMLoc getStartLoc() const { return StartLoc; }

  /// getEndLoc - Gets location of the last token of this operand
  SMLoc getEndLoc() const { return EndLoc; }

  unsigned getReg() const {
    assert(Kind == K_Register && "Invalid type access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert(Kind == K_Immediate && "Invalid type access!");
    return Imm.Val;
  }

  StringRef getToken() const {
    assert(Kind == K_Token && "Invalid type access!");
    return StringRef(Tok.Data, Tok.Length);
  }

  unsigned getMemBase() const {
    assert((Kind == K_Memory) && "Invalid access!");
    return Mem.BaseReg;
  }

  const MCExpr *getMemOff() const {
    assert((Kind == K_Memory) && "Invalid access!");
    return Mem.Off;
  }

  // Functions for testing operand type
  bool isReg() const { return Kind == K_Register; }
  bool isImm() const { return Kind == K_Immediate; }
  bool isSImm9() const { return Kind == K_Immediate; }
  bool isSImm14() const { return Kind == K_Immediate; }
  bool isSImm19() const { return Kind == K_Immediate; }
  bool isToken() const { return Kind == K_Token; }
  bool isMemS10() const { return Kind == K_Memory; }
  bool isMemS14() const { return Kind == K_Memory; }
  bool isMemS15() const { return Kind == K_Memory; }
  bool isMemV10() const { return Kind == K_Memory; }
  bool isMemV15() const { return Kind == K_Memory; }
  bool isMem() const { return Kind == K_Memory; }

  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    // Add as immediates where possible. Null MCExpr = 0
    if (Expr == 0)
      Inst.addOperand(MCOperand::createImm(0));
    else if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(Expr));
  }

  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  void addSImm9Operands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  void addSImm14Operands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  void addSImm19Operands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  void addMemS10Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getMemBase()));
    addExpr(Inst, getMemOff());
  }

  void addMemS14Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getMemBase()));
    addExpr(Inst, getMemOff());
  }

  void addMemS15Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getMemBase()));
    addExpr(Inst, getMemOff());
  }

  void addMemV10Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getMemBase()));
    addExpr(Inst, getMemOff());
  }

  void addMemV15Operands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getMemBase()));
    addExpr(Inst, getMemOff());
  }

  void print(raw_ostream &OS) const {
    switch (Kind) {
    case K_Token:
      OS << "Tok ";
      OS.write(Tok.Data, Tok.Length);
      break;
    case K_Register:
      OS << "Reg " << Reg.RegNum;
      break;
    case K_Immediate:
      OS << "Imm ";
      OS << *Imm.Val;
      break;
    case K_Memory:
      OS << "Mem " << Mem.BaseReg << " ";
      if (Mem.Off)
        OS << *Mem.Off;
      else
        OS << "0";

      break;
    }
  }

  static std::unique_ptr<NyuziOperand> createToken(StringRef Str, SMLoc S) {
    auto Op = make_unique<NyuziOperand>(K_Token);
    Op->Tok.Data = Str.data();
    Op->Tok.Length = Str.size();
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static std::unique_ptr<NyuziOperand> createReg(unsigned RegNo, SMLoc S,
                                                 SMLoc E) {
    auto Op = make_unique<NyuziOperand>(K_Register);
    Op->Reg.RegNum = RegNo;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<NyuziOperand> createImm(const MCExpr *Val, SMLoc S,
                                                 SMLoc E) {
    auto Op = make_unique<NyuziOperand>(K_Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<NyuziOperand>
  createMem(unsigned BaseReg, const MCExpr *Offset, SMLoc S, SMLoc E) {
    auto Op = make_unique<NyuziOperand>(K_Memory);
    Op->Mem.BaseReg = BaseReg;
    Op->Mem.Off = Offset;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }
};
} // end anonymous namespace.

// Auto-generated by TableGen
static unsigned MatchRegisterName(StringRef Name);
static std::string NyuziMnemonicSpellCheck(StringRef S,
                                           const FeatureBitset &FBS,
                                           unsigned VariantID = 0);

bool NyuziAsmParser::MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                             OperandVector &Operands,
                                             MCStreamer &Out,
                                             uint64_t &ErrorInfo,
                                             bool MatchingInlineAsm) {
  MCInst Inst;
  SMLoc ErrorLoc;
  SmallVector<std::pair<unsigned, std::string>, 4> MapAndConstraints;

  switch (MatchInstructionImpl(Operands, Inst, ErrorInfo, MatchingInlineAsm)) {
  default:
    break;
  case Match_Success:
    if (ProcessInstruction(Inst, IDLoc, Out))
      return true;
    return false;
  case Match_MissingFeature:
    return Error(IDLoc, "instruction use requires option to be enabled");
  case Match_MnemonicFail: {
    FeatureBitset FBS = ComputeAvailableFeatures(getSTI().getFeatureBits());
    std::string Suggestion = NyuziMnemonicSpellCheck(((NyuziOperand&)*Operands[0])
      .getToken(), FBS);
    return Error(IDLoc, "invalid instruction" + Suggestion);
  }
  case Match_InvalidOperand:
    ErrorLoc = IDLoc;
    if (ErrorInfo != ~0U) {
      if (ErrorInfo >= Operands.size())
        return Error(IDLoc, "too few operands for instruction");

      ErrorLoc = ((NyuziOperand &)*Operands[ErrorInfo]).getStartLoc();
      if (ErrorLoc == SMLoc())
        ErrorLoc = IDLoc;
    }

    return Error(ErrorLoc, "invalid operand for instruction");
  }

  llvm_unreachable("Unknown match type detected!");
}

bool NyuziAsmParser::ParseRegister(unsigned &RegNo, SMLoc &StartLoc,
                                   SMLoc &EndLoc) {
  StartLoc = Parser.getTok().getLoc();
  EndLoc = Parser.getTok().getEndLoc();

  switch (getLexer().getKind()) {
  default:
    return true;
  case AsmToken::Identifier:
    RegNo = MatchRegisterName(getLexer().getTok().getIdentifier());
    if (RegNo == 0)
      return true;

    getLexer().Lex();
    return false;
  }

  return true;
}

OperandMatchResultTy
NyuziAsmParser::ParseImmediate(OperandVector &Operands, int MaxBits,
                               bool isSigned) {
  NyuziMCExpr::VariantKind Kind = NyuziMCExpr::VK_Nyuzi_NONE;
  SMLoc S = Parser.getTok().getLoc();
  if (getLexer().getKind() == AsmToken::Identifier) {
    StringRef lookahead = getLexer().getTok().getString();
    if (lookahead.equals_lower("hi"))
      Kind = NyuziMCExpr::VK_Nyuzi_ABS_HI;
    else if (lookahead.equals_lower("lo"))
      Kind = NyuziMCExpr::VK_Nyuzi_ABS_LO;
  }

  if (Kind != NyuziMCExpr::VK_Nyuzi_NONE) {
    getLexer().Lex(); // Eat prefix

    if (getLexer().getKind() != AsmToken::LParen) {
      Error(getLexer().getLoc(), "expected '('");
      return MatchOperand_ParseFail;
    }
    getLexer().Lex(); // eat '('

    // Parse identifier
    StringRef Identifier;
    if (Parser.parseIdentifier(Identifier)) {
      Error(getLexer().getLoc(), "expected identifier");
      return MatchOperand_ParseFail;
    }

    if (getLexer().getKind() != AsmToken::RParen) {
      Error(getLexer().getLoc(), "expected ')'");
      return MatchOperand_ParseFail;
    }
    getLexer().Lex(); // eat ')'

    MCSymbol *Sym = getContext().getOrCreateSymbol(Identifier);
    const MCExpr *Expr = MCSymbolRefExpr::create(Sym, getContext());
    if (Kind != NyuziMCExpr::VK_Nyuzi_NONE)
      Expr = NyuziMCExpr::create(Kind, Expr, getContext());

    SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
    Operands.push_back(NyuziOperand::createImm(Expr, S, E));
    return MatchOperand_Success;
  } else {
    // If this is a register, bail out, as this isn't an immediate.
    if (getLexer().getKind() == AsmToken::Identifier
      && MatchRegisterName(getLexer().getTok().getIdentifier()) != 0)
      return MatchOperand_NoMatch;

    const MCExpr *EVal;
    if (Parser.parseExpression(EVal))
      return MatchOperand_ParseFail;

    int64_t ans;
    EVal->evaluateAsAbsolute(ans);
    S = Parser.getTok().getLoc();
    if (MaxBits < 32) {
      int MaxVal;
      int MinVal;
      if (isSigned) {
        MaxVal = 0xffffffffu >> (33 - MaxBits);
        MinVal = 0xffffffff << (MaxBits - 1);
      } else {
        MaxVal = 0xffffffffu >> (32 - MaxBits);
        MinVal = 0;
      }

      if (ans > MaxVal || ans < MinVal) {
        Error(S, "immediate operand out of range");
        return MatchOperand_ParseFail;
      }
    }

    SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
    Operands.push_back(NyuziOperand::createImm(EVal, S, E));
    return MatchOperand_Success;
  }
}

bool NyuziAsmParser::ParseOperand(OperandVector &Operands, StringRef Mnemonic) {
  // Check if the current operand has a custom associated parser, if so, try to
  // custom parse the operand.
  OperandMatchResultTy ResTy = MatchOperandParserImpl(Operands, Mnemonic);
  if (ResTy == MatchOperand_Success)
    return false;
  else if (ResTy == MatchOperand_ParseFail)
    return true;

  // MatchOperand_NoMatch. No custom parser, fall back to matching generically.

  // Attempt to parse token as register
  unsigned RegNo;
  SMLoc S;
  SMLoc E;
  if (!ParseRegister(RegNo, S, E)) {
    Operands.push_back(NyuziOperand::createReg(RegNo, S, E));
    return false;
  }

  // Parse as numeric expression/immediate
  const MCExpr *IdVal;
  S = Parser.getTok().getLoc();
  if (!Parser.parseExpression(IdVal)) {
    E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
    Operands.push_back(NyuziOperand::createImm(IdVal, S, E));
    return false;
  }

  // Error
  return true;
}

bool NyuziAsmParser::ProcessInstruction(MCInst &Inst, const SMLoc &Loc,
                                        MCStreamer &Out) {

  switch (Inst.getOpcode()) {
  case Nyuzi::LI: {
    // load immediate (li) pseudo instruction
    MCOperand Value = Inst.getOperand(1);
    int64_t IntVal = Value.getImm();
    if (isInt<14>(IntVal)) {
      // This will fit in the immediate field of the instruction.
      // (assumes scalar move)
      MCInst NewInst;
      NewInst.setOpcode(Nyuzi::MOVESimm);
      NewInst.addOperand(Inst.getOperand(0)); // Dest
      NewInst.addOperand(Inst.getOperand(1)); // Value
      NewInst.setLoc(Loc);
      Out.EmitInstruction(NewInst, getSTI());
    } else {
      // Need to use movehi to set high bits
      MCInst NewInst;
      NewInst.setOpcode(Nyuzi::MOVEHI);
      NewInst.addOperand(Inst.getOperand(0)); // Dest
      NewInst.addOperand(MCOperand::createImm((IntVal >> 13) & 0x7ffff));
      NewInst.setLoc(Loc);
      Out.EmitInstruction(NewInst, getSTI());

      if ((IntVal & 0x1fff) != 0) {
        // Also need to set low bits
        MCInst NewInst;
        NewInst.setOpcode(Nyuzi::ORSSI);
        NewInst.addOperand(Inst.getOperand(0)); // Dest
        NewInst.addOperand(Inst.getOperand(0)); // Source
        NewInst.addOperand(MCOperand::createImm(IntVal & 0x1fff));
        NewInst.setLoc(Loc);
        Out.EmitInstruction(NewInst, getSTI());
      }
    }
    break;
  }

  case Nyuzi::LEA_SYM: {
    const MCExpr *Symbol = Inst.getOperand(1).getExpr();
    const MCExpr *GotSym = NyuziMCExpr::create(NyuziMCExpr::VK_Nyuzi_GOT,
        Symbol, getContext());

    if (getContext().getObjectFileInfo()->isPositionIndependent()) {
      MCInst LoadInst;
      LoadInst.setOpcode(Nyuzi::LW);
      LoadInst.addOperand(Inst.getOperand(0)); // Dest
      LoadInst.addOperand(MCOperand::createReg(Nyuzi::GP_REG));
      LoadInst.addOperand(MCOperand::createExpr(GotSym));
      LoadInst.setLoc(Loc);
      Out.EmitInstruction(LoadInst, getSTI());
    } else {
      // Load high bits
      MCInst NewInst1;
      NewInst1.setOpcode(Nyuzi::MOVEHI);
      NewInst1.addOperand(Inst.getOperand(0)); // Dest
      const MCExpr *HighAddr = NyuziMCExpr::create(NyuziMCExpr::VK_Nyuzi_ABS_HI,
        Symbol, getContext());
      NewInst1.addOperand(MCOperand::createExpr(HighAddr));
      NewInst1.setLoc(Loc);
      Out.EmitInstruction(NewInst1, getSTI());

      // Load low bits
      MCInst NewInst2;
      NewInst2.setOpcode(Nyuzi::ORSSI);
      NewInst2.addOperand(Inst.getOperand(0)); // Dest
      NewInst2.addOperand(Inst.getOperand(0)); // Source
      const MCExpr *LowAddr = NyuziMCExpr::create(NyuziMCExpr::VK_Nyuzi_ABS_LO,
        Symbol, getContext());
      NewInst2.addOperand(MCOperand::createExpr(LowAddr));
      NewInst2.setLoc(Loc);
      Out.EmitInstruction(NewInst2, getSTI());
    }
    break;
  }

  default:
    Inst.setLoc(Loc);
    Out.EmitInstruction(Inst, getSTI());
  }

  return false;
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperandS10(OperandVector &Operands) {
  return ParseMemoryOperand(Operands, 10, false);
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperandS14(OperandVector &Operands) {
  return ParseMemoryOperand(Operands, 14, false);
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperandS15(OperandVector &Operands) {
  return ParseMemoryOperand(Operands, 15, false);
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperandV10(OperandVector &Operands) {
  return ParseMemoryOperand(Operands, 10, true);
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperandV15(OperandVector &Operands) {
  return ParseMemoryOperand(Operands, 15, true);
}

OperandMatchResultTy
NyuziAsmParser::ParseMemoryOperand(OperandVector &Operands, int MaxBits,
                                   bool OpIsVector) {
  SMLoc S = Parser.getTok().getLoc();
  const MCExpr *Offset = nullptr;

  if (getLexer().getKind() == AsmToken::Identifier) {
    // Is of the form load_xx reg, got(symbol)
    StringRef lookahead = getLexer().getTok().getString();
    if (!lookahead.equals_lower("got")) {
      // If we're trying to parse LEA_MEM, this might be LEA_SYM
      return MatchOperand_NoMatch;
    }

    if (MaxBits != 15 || OpIsVector) {
      Error(Parser.getTok().getLoc(), "cannot use got expression with this type of memory access");
      return MatchOperand_ParseFail;
    }

    getLexer().Lex(); // eat 'got'
    if (!getLexer().is(AsmToken::LParen)) {
      Error(Parser.getTok().getLoc(), "expected (");
      return MatchOperand_ParseFail;
    }

    getLexer().Lex(); // eat '('

    StringRef Identifier;
    if (Parser.parseIdentifier(Identifier)) {
      Error(getLexer().getLoc(), "expected identifier");
      return MatchOperand_ParseFail;
    }

    if (getLexer().getKind() != AsmToken::RParen) {
      Error(getLexer().getLoc(), "expected ')'");
      return MatchOperand_ParseFail;
    }
    getLexer().Lex(); // eat ')'

    MCSymbol *Sym = getContext().getOrCreateSymbol(Identifier);
    const MCExpr *SymExpr = MCSymbolRefExpr::create(Sym, getContext());
    Offset = NyuziMCExpr::create(NyuziMCExpr::VK_Nyuzi_GOT,
        SymExpr, getContext());
  } else if (getLexer().is(AsmToken::Integer) || getLexer().is(AsmToken::Minus)
    || getLexer().is(AsmToken::Plus)) {
    // Has a memory offset. e.g. load_32 s0, -12(s1)
    if (Parser.parseExpression(Offset))
      return MatchOperand_ParseFail;

    // Check if offset is in range
    int MaxVal = 0xffffffffu >> (33 - MaxBits);
    int MinVal = 0xffffffff << (MaxBits - 1);
    const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Offset);
    if (!CE || CE->getValue() > MaxVal || CE->getValue() < MinVal) {
      Error(Parser.getTok().getLoc(), "offset out of range");
      return MatchOperand_ParseFail;
    }
  }

  if (!getLexer().is(AsmToken::LParen)) {
    Error(Parser.getTok().getLoc(), "expected (");
    return MatchOperand_ParseFail;
  }

  getLexer().Lex(); // eat '('
  unsigned RegNo;
  SMLoc _S, _E;
  if (ParseRegister(RegNo, _S, _E)) {
    Error(Parser.getTok().getLoc(), "invalid register");
    return MatchOperand_ParseFail;
  }

  bool RegIsVector = NyuziMCRegisterClasses[Nyuzi::VR512RegClassID]
    .contains(RegNo);
  if (RegIsVector != OpIsVector) {
    Error(_S, "invalid operand for instruction");
    return MatchOperand_ParseFail;
  }

  if (getLexer().isNot(AsmToken::RParen)) {
    Error(Parser.getTok().getLoc(), "expected )");
    return MatchOperand_ParseFail;
  }

  getLexer().Lex(); // eat ')'

  SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
  Operands.push_back(NyuziOperand::createMem(RegNo, Offset, S, E));

  return MatchOperand_Success;
}

OperandMatchResultTy
NyuziAsmParser::ParseSImm9Value(OperandVector &Operands) {
  return ParseImmediate(Operands, 9, true);
}

OperandMatchResultTy
NyuziAsmParser::ParseSImm14Value(OperandVector &Operands) {
  return ParseImmediate(Operands, 14, true);
}

OperandMatchResultTy
NyuziAsmParser::ParseSImm19Value(OperandVector &Operands) {
  return ParseImmediate(Operands, 19, false);
}

bool NyuziAsmParser::ParseInstruction(ParseInstructionInfo &Info,
                                      StringRef Mnemonic, SMLoc NameLoc,
                                      OperandVector &Operands) {

  Operands.push_back(NyuziOperand::createToken(Mnemonic, NameLoc));

  // If there are no more operands, then finish
  if (getLexer().is(AsmToken::EndOfStatement))
    return false;

  // parse operands
  for (;;) {
    if (ParseOperand(Operands, Mnemonic))
      return true;

    if (getLexer().isNot(AsmToken::Comma))
      break;

    // Consume comma token
    getLexer().Lex();
  }

  return false;
}

bool NyuziAsmParser::ParseDirective(AsmToken DirectiveID) { return true; }

extern "C" void LLVMInitializeNyuziAsmParser() {
  RegisterMCAsmParser<NyuziAsmParser> X(TheNyuziTarget);
}

#define GET_MNEMONIC_SPELL_CHECKER
#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#include "NyuziGenAsmMatcher.inc"
