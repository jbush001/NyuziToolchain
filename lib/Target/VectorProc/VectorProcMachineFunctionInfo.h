//===- VectorProcMachineFunctionInfo.h - VectorProc Machine Function Info -*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares  VectorProc specific per-machine-function information.
//
//===----------------------------------------------------------------------===//
#ifndef VECTORPROCMACHINEFUNCTIONINFO_H
#define VECTORPROCMACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

class VectorProcMachineFunctionInfo : public MachineFunctionInfo {
public:
  VectorProcMachineFunctionInfo() : SRetReturnReg(0) {}

  explicit VectorProcMachineFunctionInfo(MachineFunction &MF)
      : SRetReturnReg(0) {}

  unsigned getSRetReturnReg() const { return SRetReturnReg; }
  void setSRetReturnReg(unsigned Reg) { SRetReturnReg = Reg; }
  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }

private:
  virtual void anchor();

  /// SRetReturnReg - Holds the virtual register into which the sret
  /// argument is passed.
  unsigned SRetReturnReg;
  int VarArgsFrameIndex;
};
}

#endif
