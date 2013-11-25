//===-- VectorProcInstPrinter.cpp - Convert VectorProc MCInst to assembly syntax ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an VectorProc MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "VectorProcInstPrinter.h"
#include "VectorProcInstrInfo.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
using namespace llvm;

#define PRINT_ALIAS_INSTR
#include "VectorProcGenAsmWriter.inc"

void VectorProcInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
  OS << StringRef(getRegisterName(RegNo)).lower();
}

void VectorProcInstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                      StringRef Annot) {

  printInstruction(MI, O);
  printAnnotation(O, Annot);
}

static void printExpr(const MCExpr *Expr, raw_ostream &OS) {
  int Offset = 0;
  const MCSymbolRefExpr *SRE;

  if (const MCBinaryExpr *BE = dyn_cast<MCBinaryExpr>(Expr)) {
    SRE = dyn_cast<MCSymbolRefExpr>(BE->getLHS());
    const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());
    assert(SRE && CE && "Binary expression must be sym+const.");
    Offset = CE->getValue();
  }
  else if (!(SRE = dyn_cast<MCSymbolRefExpr>(Expr)))
    assert(false && "Unexpected MCExpr type.");

  MCSymbolRefExpr::VariantKind Kind = SRE->getKind();

  OS << SRE->getSymbol();

  if (Offset) {
    if (Offset > 0)
      OS << '+';
    OS << Offset;
  }

  if (Kind != MCSymbolRefExpr::VK_None)
    OS << ')';
}

void VectorProcInstPrinter::printCPURegs(const MCInst *MI, unsigned OpNo,
    raw_ostream &O) {
  printRegName(O, MI->getOperand(OpNo).getReg());
}

void VectorProcInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
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
  printExpr(Op.getExpr(), O);
}

void VectorProcInstPrinter::printUnsignedImm(const MCInst *MI, int opNum,
    raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);
  if (MO.isImm())
    O << (unsigned short int)MO.getImm();
  else
    printOperand(MI, opNum, O);
}

void VectorProcInstPrinter::
printMemOperand(const MCInst *MI, int opNum, raw_ostream &O)
{
  if (MI->getOperand(opNum + 1).isExpr())
  {
    // PC relative memory access to a local label
    printOperand(MI, opNum + 1, O);
  }
  else
  {
    // Register/offset
    assert(MI->getOperand(opNum).isReg());
    assert(MI->getOperand(opNum + 1).isImm());

    if (MI->getOperand(opNum + 1).getImm())
      printOperand(MI, opNum+1, O);

    O << "(";
    printOperand(MI, opNum, O);
    O << ")";
  }
}

void VectorProcInstPrinter::
printJumpTableOperand(const MCInst *MI, int opNum, raw_ostream &O)
{
  const MCOperand &Op = MI->getOperand(2);
  printExpr(Op.getExpr(), O);
}

