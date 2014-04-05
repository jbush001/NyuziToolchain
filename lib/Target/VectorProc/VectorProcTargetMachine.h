//===-- VectorProcTargetMachine.h - Define TargetMachine for VectorProc ---*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the VectorProc specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCTARGETMACHINE_H
#define VECTORPROCTARGETMACHINE_H

#include "VectorProcFrameLowering.h"
#include "VectorProcISelLowering.h"
#include "VectorProcInstrInfo.h"
#include "VectorProcSelectionDAGInfo.h"
#include "VectorProcSubtarget.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class VectorProcTargetMachine : public LLVMTargetMachine {
public:
  VectorProcTargetMachine(const Target &T, StringRef TT, StringRef CPU,
                          StringRef FS, const TargetOptions &Options,
                          Reloc::Model RM, CodeModel::Model CM,
                          CodeGenOpt::Level OL);

  virtual const VectorProcInstrInfo *getInstrInfo() const override { return &InstrInfo; }
  virtual const TargetFrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }
  virtual const VectorProcSubtarget *getSubtargetImpl() const override {
    return &Subtarget;
  }
  virtual const VectorProcRegisterInfo *getRegisterInfo() const override {
    return &InstrInfo.getRegisterInfo();
  }
  virtual const VectorProcTargetLowering *getTargetLowering() const override {
    return &TLInfo;
  }
  virtual const VectorProcSelectionDAGInfo *getSelectionDAGInfo() const override {
    return &TSInfo;
  }
  virtual const DataLayout *getDataLayout() const override { return &DL; }

  // Pass Pipeline Configuration
  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

private:
  VectorProcSubtarget Subtarget;
  const DataLayout DL; // Calculates type size & alignment
  VectorProcInstrInfo InstrInfo;
  VectorProcTargetLowering TLInfo;
  VectorProcSelectionDAGInfo TSInfo;
  VectorProcFrameLowering FrameLowering;
};

} // end namespace llvm

#endif
