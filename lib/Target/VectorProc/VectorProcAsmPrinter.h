//===-- MipsAsmPrinter.h - Mips LLVM Assembly Printer ----------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// VectorProc Assembly printer class.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCASMPRINTER_H
#define VECTORPROCASMPRINTER_H

#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Target/TargetMachine.h"
#include "VectorProcMCInstLower.h"

namespace llvm {
class MCStreamer;
class MachineInstr;
class MachineBasicBlock;
class Module;
class raw_ostream;

class VectorProcAsmPrinter : public AsmPrinter {
  VectorProcMCInstLower MCInstLowering;
public:
  explicit VectorProcAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
    : AsmPrinter(TM, Streamer),
     MCInstLowering(*this) 
  {
  }

  virtual const char *getPassName() const {
    return "VectorProc Assembly Printer";
  }

  void printOperand(const MachineInstr *MI, int opNum, raw_ostream &OS);
  void printMemOperand(const MachineInstr *MI, int opNum, raw_ostream &OS,
                       const char *Modifier = 0);
  virtual void EmitInstruction(const MachineInstr *MI);
  
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       unsigned AsmVariant, const char *ExtraCode,
                       raw_ostream &O);
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                             unsigned AsmVariant, const char *ExtraCode,
                             raw_ostream &O);

  virtual bool isBlockOnlyReachableByFallthrough(const MachineBasicBlock *MBB)
                     const;

  virtual MachineLocation getDebugValueLocation(const MachineInstr *MI) const;
  virtual void EmitFunctionBodyStart();
  virtual void EmitFunctionBodyEnd();
  virtual void EmitConstantPool();
  virtual void EmitInlineJumpTable(const MachineInstr *MI);

private:
  MCSymbol *GetJumpTableLabel(unsigned uid) const;
};
}


#endif
