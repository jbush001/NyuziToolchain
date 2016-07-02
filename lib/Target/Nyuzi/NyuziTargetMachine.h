//===-- NyuziTargetMachine.h - Define TargetMachine for Nyuzi ------------===//
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

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZITARGETMACHINE_H
#define LLVM_LIB_TARGET_NYUZI_NYUZITARGETMACHINE_H

#include "NyuziSubtarget.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class NyuziTargetMachine : public LLVMTargetMachine {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  NyuziSubtarget Subtarget;

public:
  NyuziTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                     StringRef FS, const TargetOptions &Options,
                     Optional<Reloc::Model> RM, CodeModel::Model CM,
                     CodeGenOpt::Level OL);

  // Pass Pipeline Configuration
  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
  const NyuziSubtarget *getSubtargetImpl(const Function &) const override {
    return &Subtarget;
  }

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }
};

} // end namespace llvm

#endif
