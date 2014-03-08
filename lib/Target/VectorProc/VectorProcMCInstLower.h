//===-- VectorProcMCInstLower.h - Lower MachineInstr to MCInst -------*- C++
//-*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// VectorProcMCInstLower - Helper class used by VectorProcAsmPrinter to convert
// MachineInstrs into MCInsts
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

class LLVM_LIBRARY_VISIBILITY VectorProcMCInstLower {
public:
  VectorProcMCInstLower(VectorProcAsmPrinter &asmprinter);
  void Initialize(MCContext *C);
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;

private:
  typedef MachineOperand::MachineOperandType MachineOperandType;

  MCOperand LowerOperand(const MachineOperand &MO, unsigned offset = 0) const;
  MCOperand LowerSymbolOperand(const MachineOperand &MO,
                               MachineOperandType MOTy, unsigned Offset) const;

  MCContext *Ctx;
  VectorProcAsmPrinter &AsmPrinter;
};
}

#endif
