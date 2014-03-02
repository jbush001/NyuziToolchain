//===-- VectorProcMCInstLower.h - Lower MachineInstr to MCInst -------*- C++
//-*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCMCINSTLOWER_H
#define VECTORPROCMCINSTLOWER_H

#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/Support/Compiler.h"

namespace llvm {
class MCContext;
class MCInst;
class MCOperand;
class MachineInstr;
class MachineFunction;
class Mangler;
class VectorProcAsmPrinter;

// VectorProcMCInstLower - Helper class used by VectorProcAsmPrinter to convert
// MachineInstrs into MCInsts
class LLVM_LIBRARY_VISIBILITY VectorProcMCInstLower {
  typedef MachineOperand::MachineOperandType MachineOperandType;
  MCContext *Ctx;
  VectorProcAsmPrinter &AsmPrinter;

public:
  VectorProcMCInstLower(VectorProcAsmPrinter &asmprinter);
  void Initialize(MCContext *C);
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;

private:
  MCOperand LowerOperand(const MachineOperand &MO, unsigned offset = 0) const;
  MCOperand LowerSymbolOperand(const MachineOperand &MO,
                               MachineOperandType MOTy, unsigned Offset) const;
};
}

#endif
