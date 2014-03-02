//===-- VectorProcMCInstLower.cpp - Convert VectorProc MachineInstr to MCInst
//---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains code to lower VectorProc MachineInstrs to their
// corresponding
// MCInst records.
//
//===----------------------------------------------------------------------===//

#include "VectorProcMCInstLower.h"
#include "VectorProcAsmPrinter.h"
#include "VectorProcInstrInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/Support/Debug.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"

#define GET_REGINFO_ENUM
#include "VectorProcGenRegisterInfo.inc"

using namespace llvm;

VectorProcMCInstLower::VectorProcMCInstLower(VectorProcAsmPrinter &asmprinter)
    : AsmPrinter(asmprinter) {}

void VectorProcMCInstLower::Initialize(MCContext *C) { Ctx = C; }

MCOperand VectorProcMCInstLower::LowerSymbolOperand(const MachineOperand &MO,
                                                    MachineOperandType MOTy,
                                                    unsigned Offset) const {
  MCSymbolRefExpr::VariantKind Kind = MCSymbolRefExpr::VK_None;
  const MCSymbol *Symbol;

  switch (MOTy) {
  case MachineOperand::MO_MachineBasicBlock:
    Symbol = MO.getMBB()->getSymbol();
    break;

  case MachineOperand::MO_GlobalAddress:
    Symbol = AsmPrinter.getSymbol(MO.getGlobal());
    Offset += MO.getOffset();
    break;

  case MachineOperand::MO_BlockAddress:
    Symbol = AsmPrinter.GetBlockAddressSymbol(MO.getBlockAddress());
    Offset += MO.getOffset();
    break;

  case MachineOperand::MO_ExternalSymbol:
    Symbol = AsmPrinter.GetExternalSymbolSymbol(MO.getSymbolName());
    Offset += MO.getOffset();
    break;

  case MachineOperand::MO_JumpTableIndex:
    Symbol = AsmPrinter.GetJTISymbol(MO.getIndex());
    break;

  case MachineOperand::MO_ConstantPoolIndex:
    Symbol = AsmPrinter.GetCPISymbol(MO.getIndex());
    Offset += MO.getOffset();
    break;

  default:
    llvm_unreachable("<unknown operand type>");
  }

  const MCSymbolRefExpr *MCSym = MCSymbolRefExpr::Create(Symbol, Kind, *Ctx);
  if (!Offset)
    return MCOperand::CreateExpr(MCSym);

  // Assume offset is never negative.
  assert(Offset > 0);

  const MCConstantExpr *OffsetExpr = MCConstantExpr::Create(Offset, *Ctx);
  const MCBinaryExpr *Add = MCBinaryExpr::CreateAdd(MCSym, OffsetExpr, *Ctx);
  return MCOperand::CreateExpr(Add);
}

MCOperand VectorProcMCInstLower::LowerOperand(const MachineOperand &MO,
                                              unsigned offset) const {
  MachineOperandType MOTy = MO.getType();

  switch (MOTy) {
  default:
    llvm_unreachable("unknown operand type");
  case MachineOperand::MO_Register:
    // Ignore all implicit register operands.
    if (MO.isImplicit())
      break;
    return MCOperand::CreateReg(MO.getReg());

  case MachineOperand::MO_Immediate:
    return MCOperand::CreateImm(MO.getImm() + offset);

  case MachineOperand::MO_MachineBasicBlock:
  case MachineOperand::MO_GlobalAddress:
  case MachineOperand::MO_ExternalSymbol:
  case MachineOperand::MO_JumpTableIndex:
  case MachineOperand::MO_ConstantPoolIndex:
  case MachineOperand::MO_BlockAddress:
    return LowerSymbolOperand(MO, MOTy, offset);

  case MachineOperand::MO_RegisterMask:
    break;
  }

  return MCOperand();
}

void VectorProcMCInstLower::Lower(const MachineInstr *MI, MCInst &OutMI) const {
  OutMI.setOpcode(MI->getOpcode());

  // XXX note that this chunk of code assumes a load instruction. It's also
  // possible for MO_ConstantPoolIndex to appear in arithmetic.  In this
  // situation, the instruction would be clobbered.
  if (MI->getNumOperands() > 1 &&
      (MI->getOperand(1).getType() == MachineOperand::MO_ConstantPoolIndex ||
       MI->getOperand(1).getType() == MachineOperand::MO_JumpTableIndex)) {
    OutMI.addOperand(LowerOperand(MI->getOperand(0))); // result

    const MachineOperand &cpEntry = MI->getOperand(1);

    // This is a PC relative constant pool access.  Add the PC register
    // to this instruction to match what the assembly parser produces
    // (and InstPrinter/Encoder expects)
    // It should look like this:
    // <MCInst #97 LWi <MCOperand Reg:8> <MCOperand Reg:3> <MCOperand
    // Expr:(foo)>>
    OutMI.addOperand(MCOperand::CreateReg(VectorProc::PC_REG));
    const MCSymbol *Symbol;
    if (MI->getOperand(1).getType() == MachineOperand::MO_ConstantPoolIndex)
      Symbol = AsmPrinter.GetCPISymbol(cpEntry.getIndex());
    else
      Symbol = AsmPrinter.GetJTISymbol(cpEntry.getIndex());

    const MCSymbolRefExpr *MCSym =
        MCSymbolRefExpr::Create(Symbol, MCSymbolRefExpr::VK_None, *Ctx);
    MCOperand MCOp = MCOperand::CreateExpr(MCSym);
    OutMI.addOperand(MCOp);
  } else {
    for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
      const MachineOperand &MO = MI->getOperand(i);
      MCOperand MCOp = LowerOperand(MO);

      if (MCOp.isValid())
        OutMI.addOperand(MCOp);
    }
  }
}
