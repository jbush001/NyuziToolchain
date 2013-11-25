//===-- VectorProcTargetMachine.cpp - Define TargetMachine for VectorProc -----------===//
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

#include "VectorProcTargetMachine.h"
#include "VectorProc.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeVectorProcTarget() {
  // Register the target.
  RegisterTargetMachine<VectorProcTargetMachine> X(TheVectorProcTarget);
}

VectorProcTargetMachine::VectorProcTargetMachine(const Target &T, StringRef TT,
    StringRef CPU, StringRef FS,
    const TargetOptions &Options,
    Reloc::Model RM, CodeModel::Model CM,
    CodeGenOpt::Level OL)
  : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
    Subtarget(TT, CPU, FS),
    DL(Subtarget.getDataLayout()),
    InstrInfo(Subtarget),
    TLInfo(*this), TSInfo(*this),
    FrameLowering(Subtarget) {
  initAsmInfo();
}

namespace {
/// VectorProc Code Generator Pass Configuration Options.
class VectorProcPassConfig : public TargetPassConfig {
public:
  VectorProcPassConfig(VectorProcTargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  VectorProcTargetMachine &getVectorProcTargetMachine() const {
    return getTM<VectorProcTargetMachine>();
  }

  virtual bool addInstSelector();
  virtual bool addPreEmitPass();
};
} // namespace

TargetPassConfig *VectorProcTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new VectorProcPassConfig(this, PM);
}

bool VectorProcPassConfig::addInstSelector() {
  addPass(createVectorProcISelDag(getVectorProcTargetMachine()));
  return false;
}

/// addPreEmitPass - This pass may be implemented by targets that want to run
/// passes immediately before machine code is emitted.  This should return
/// true if -print-machineinstrs should print out the code after the passes.
bool VectorProcPassConfig::addPreEmitPass() {
  return true;
}
