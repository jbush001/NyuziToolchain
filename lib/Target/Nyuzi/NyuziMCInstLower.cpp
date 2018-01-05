//===-- NyuziMCInstLower.cpp - Convert Nyuzi MachineInstr to MCInst -------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "NyuziMCInstLower.h"
#include "MCTargetDesc/NyuziBaseInfo.h"
#include "MCTargetDesc/NyuziMCExpr.h"
#include "NyuziAsmPrinter.h"
#include "NyuziInstrInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"

#define GET_REGINFO_ENUM
#include "NyuziGenRegisterInfo.inc"

using namespace llvm;

NyuziMCInstLower::NyuziMCInstLower(NyuziAsmPrinter &asmprinter)
    : AsmPrinter(asmprinter) {}

void NyuziMCInstLower::Initialize(MCContext *C) { Ctx = C; }

void NyuziMCInstLower::Lower(const MachineInstr *MI, MCInst &OutMI) const {
  OutMI.setOpcode(MI->getOpcode());
  for (const MachineOperand &MO : MI->operands()) {
    MCOperand MCOp = LowerOperand(MO);
    if (MCOp.isValid())
      OutMI.addOperand(MCOp);
  }
}

MCOperand NyuziMCInstLower::LowerOperand(const MachineOperand &MO) const {
  switch (MO.getType()) {
  default:
    llvm_unreachable("unknown operand type");
  case MachineOperand::MO_Register:
    // Ignore all implicit register operands.
    if (MO.isImplicit())
      break;

    return MCOperand::createReg(MO.getReg());
  case MachineOperand::MO_Immediate:
    return MCOperand::createImm(MO.getImm());
  case MachineOperand::MO_MachineBasicBlock:
    return MCOperand::createExpr(MCSymbolRefExpr::create(
        MO.getMBB()->getSymbol(), *Ctx));
  case MachineOperand::MO_GlobalAddress:
    return LowerSymbolOperand(MO, AsmPrinter.getSymbol(MO.getGlobal()));
  case MachineOperand::MO_ExternalSymbol:
    return LowerSymbolOperand(MO, AsmPrinter.GetExternalSymbolSymbol(
                              MO.getSymbolName()));
  case MachineOperand::MO_JumpTableIndex:
    return LowerSymbolOperand(MO, AsmPrinter.GetJTISymbol(MO.getIndex()));
  case MachineOperand::MO_ConstantPoolIndex:
    return LowerSymbolOperand(MO, AsmPrinter.GetCPISymbol(MO.getIndex()));
  case MachineOperand::MO_BlockAddress:
    return LowerSymbolOperand(MO, AsmPrinter.GetBlockAddressSymbol(
                              MO.getBlockAddress()));
  case MachineOperand::MO_RegisterMask:
    break;
  }

  return MCOperand();
}

MCOperand NyuziMCInstLower::LowerSymbolOperand(const MachineOperand &MO,
                                               MCSymbol *Sym) const {
  NyuziMCExpr::VariantKind Kind;
  switch (MO.getTargetFlags()) {
  case Nyuzi::MO_NO_FLAG:
    Kind = NyuziMCExpr::VK_Nyuzi_NONE;
    break;
  case Nyuzi::MO_ABS_HI:
    Kind = NyuziMCExpr::VK_Nyuzi_ABS_HI;
    break;
  case Nyuzi::MO_ABS_LO:
    Kind = NyuziMCExpr::VK_Nyuzi_ABS_LO;
    break;
  case Nyuzi::MO_GOT:
    Kind = NyuziMCExpr::VK_Nyuzi_GOT;
    break;
  default:
    llvm_unreachable("Unknown target flag on operand");
  }

  const MCExpr *Expr = MCSymbolRefExpr::create(Sym,
   MCSymbolRefExpr::VK_None, *Ctx);

  if (!MO.isJTI() && MO.getOffset()) {
    const MCConstantExpr *OffsetExpr = MCConstantExpr::create(MO.getOffset(), *Ctx);
    Expr = MCBinaryExpr::createAdd(Expr, OffsetExpr, *Ctx);
  }

  if (Kind != NyuziMCExpr::VK_Nyuzi_NONE)
    Expr = NyuziMCExpr::create(Kind, Expr, *Ctx);

  return MCOperand::createExpr(Expr);
}
