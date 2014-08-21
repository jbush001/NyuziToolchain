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


  // Pass Pipeline Configuration
  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
  virtual const VectorProcSubtarget *getSubtargetImpl() const override {
    return &Subtarget;
  }

private:
  VectorProcSubtarget Subtarget;
};

} // end namespace llvm

#endif
