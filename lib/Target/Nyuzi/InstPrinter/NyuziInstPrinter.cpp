//===-- NyuziInstPrinter.cpp - Convert Nyuzi MCInst to assembly syntax ---===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an Nyuzi MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"

#include "NyuziInstPrinter.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "NyuziInstrInfo.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#include "NyuziGenAsmWriter.inc"

void NyuziInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
  OS << StringRef(getRegisterName(RegNo)).lower();
}

void NyuziInstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                 StringRef Annot, const MCSubtargetInfo &STI) {

  // NOP is or s0, s0, 0
  if (MI->getOpcode() == Nyuzi::ORSSI && MI->getOperand(0).isReg() &&
      MI->getOperand(0).getReg() == Nyuzi::S0 && MI->getOperand(1).isReg() &&
      MI->getOperand(1).getReg() == Nyuzi::S0 && MI->getOperand(2).isImm() &&
      MI->getOperand(2).getImm() == 0) {
    O << "\tnop";
    return;
  }

  printInstruction(MI, O);
  printAnnotation(O, Annot);
}

void NyuziInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(O, Op.getReg());
    return;
  }

  if (Op.isImm()) {
    O << Op.getImm();
    return;
  }

  assert(Op.isExpr() && "unknown operand kind in printOperand");
  Op.getExpr()->print(O, &MAI, true);
}

void NyuziInstPrinter::printMemOperand(const MCInst *MI, int opNum,
                                       raw_ostream &O) {

  const MCOperand &Op1 = MI->getOperand(opNum + 1);
  if (!Op1.isImm() || Op1.getImm() != 0)
    printOperand(MI, opNum + 1, O);

  O << "(";
  printOperand(MI, opNum, O);
  O << ")";
}
