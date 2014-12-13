//===-- NyuziTargetMachine.h - Define TargetMachine for Nyuzi ---*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Nyuzi specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef NYUZITARGETMACHINE_H
#define NYUZITARGETMACHINE_H

#include "NyuziSubtarget.h"
#include "NyuziTargetObjectFile.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class NyuziTargetMachine : public LLVMTargetMachine {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
public:
  NyuziTargetMachine(const Target &T, StringRef TT, StringRef CPU,
                          StringRef FS, const TargetOptions &Options,
                          Reloc::Model RM, CodeModel::Model CM,
                          CodeGenOpt::Level OL);


  // Pass Pipeline Configuration
  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
  virtual const NyuziSubtarget *getSubtargetImpl() const override {
    return &Subtarget;
  }

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }

private:
  NyuziSubtarget Subtarget;
};

} // end namespace llvm

#endif
