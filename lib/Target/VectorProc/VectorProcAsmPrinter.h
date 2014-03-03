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

//
// The name is a bit misleading.  Because we use the MC layer for code
// generation, the job of this class is now to convert MachineInstrs into MCInsts.
// Most of the work is done by MCInstLowering (which in turn uses code generated
// by TableGen).
//
class VectorProcAsmPrinter : public AsmPrinter {
  VectorProcMCInstLower MCInstLowering;

public:
  explicit VectorProcAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
      : AsmPrinter(TM, Streamer), MCInstLowering(*this) {}

  virtual const char *getPassName() const LLVM_OVERRIDE {
    return "VectorProc Assembly Printer";
  }

  virtual void EmitInstruction(const MachineInstr *MI) LLVM_OVERRIDE;
  virtual void EmitFunctionBodyStart() LLVM_OVERRIDE;
  virtual void EmitFunctionBodyEnd() LLVM_OVERRIDE;
  virtual void EmitConstantPool() LLVM_OVERRIDE;

  // Print operand for inline assembly
  virtual bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       unsigned AsmVariant, const char *ExtraCode,
                       raw_ostream &O) LLVM_OVERRIDE;
  virtual bool PrintAsmMemoryOperand(const MachineInstr *MI,
                             unsigned OpNum, unsigned AsmVariant,
                             const char *ExtraCode,
                             raw_ostream &O) LLVM_OVERRIDE;

private:
  MCSymbol *GetJumpTableLabel(unsigned uid) const;
  void EmitInlineJumpTable(const MachineInstr *MI);
};
}

#endif
