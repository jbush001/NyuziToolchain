//===-- NyuziTargetMachine.cpp - Define TargetMachine for Nyuzi
//-----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#include "NyuziTargetMachine.h"
#include "Nyuzi.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeNyuziTarget() {
  // Register the target.
  RegisterTargetMachine<NyuziTargetMachine> X(TheNyuziTarget);
}

NyuziTargetMachine::NyuziTargetMachine(const Target &T, StringRef TT,
                                                 StringRef CPU, StringRef FS,
                                                 const TargetOptions &Options,
                                                 Reloc::Model RM,
                                                 CodeModel::Model CM,
                                                 CodeGenOpt::Level OL)
    : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
      Subtarget(TT, CPU, FS, this) {
  initAsmInfo();
}

namespace {
/// Nyuzi Code Generator Pass Configuration Options.
class NyuziPassConfig : public TargetPassConfig {
public:
  NyuziPassConfig(NyuziTargetMachine *TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  NyuziTargetMachine &getNyuziTargetMachine() const {
    return getTM<NyuziTargetMachine>();
  }

  virtual bool addInstSelector() override;
  virtual bool addPreEmitPass() override;
};
} // namespace

TargetPassConfig *
NyuziTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new NyuziPassConfig(this, PM);
}

bool NyuziPassConfig::addInstSelector() {
  addPass(createNyuziISelDag(getNyuziTargetMachine()));
  return false;
}

/// addPreEmitPass - This pass may be implemented by targets that want to run
/// passes immediately before machine code is emitted.  This should return
/// true if -print-machineinstrs should print out the code after the passes.
bool NyuziPassConfig::addPreEmitPass() { return true; }
