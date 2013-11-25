//===- VectorProcMachineFunctionInfo.h - VectorProc Machine Function Info -*- C++ -*-===//
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
  virtual void anchor();
private:

  /// VarArgsFrameOffset - Frame offset to start of varargs area.
  int VarArgsFrameOffset;

  /// SRetReturnReg - Holds the virtual register into which the sret
  /// argument is passed.
  unsigned SRetReturnReg;
public:
  VectorProcMachineFunctionInfo()
    : VarArgsFrameOffset(0), SRetReturnReg(0) {}
  explicit VectorProcMachineFunctionInfo(MachineFunction &MF)
    : VarArgsFrameOffset(0), SRetReturnReg(0) {}

  int getVarArgsFrameOffset() const {
    return VarArgsFrameOffset;
  }
  void setVarArgsFrameOffset(int Offset) {
    VarArgsFrameOffset = Offset;
  }

  unsigned getSRetReturnReg() const {
    return SRetReturnReg;
  }
  void setSRetReturnReg(unsigned Reg) {
    SRetReturnReg = Reg;
  }
};
}

#endif
