//===-- NyuziMCInstLower.h - Lower MachineInstr to MCInst ----*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===--------------------------------------------------------------------===//
//
// NyuziMCInstLower - Helper class used by NyuziAsmPrinter to convert
// MachineInstrs into MCInsts
//
//===--------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIMCINSTLOWER_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIMCINSTLOWER_H

#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/Support/Compiler.h"

namespace llvm {
class MCContext;
class MCInst;
class MCOperand;
class MachineInstr;
class NyuziAsmPrinter;

class LLVM_LIBRARY_VISIBILITY NyuziMCInstLower {
public:
  explicit NyuziMCInstLower(NyuziAsmPrinter &asmprinter);
  void Initialize(MCContext *C);
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;

private:
  MCOperand LowerOperand(const MachineOperand &MO) const;
  MCOperand LowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;

  MCContext *Ctx = nullptr;
  NyuziAsmPrinter &AsmPrinter;
};

} // namespace llvm

#endif
