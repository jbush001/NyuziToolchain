//===-- NyuziTargetMachine.cpp - Define TargetMachine for Nyuzi -----------===//
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
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "Nyuzi.h"
#include "NyuziTargetObjectFile.h"
#include "NyuziTargetTransformInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

extern "C" void LLVMInitializeNyuziTarget() {
  // Register the target.
  RegisterTargetMachine<NyuziTargetMachine> X(TheNyuziTarget);
}

namespace {
/// Nyuzi Code Generator Pass Configuration Options.
class NyuziPassConfig : public TargetPassConfig {
public:
  NyuziPassConfig(NyuziTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  NyuziTargetMachine &getNyuziTargetMachine() const {
    return getTM<NyuziTargetMachine>();
  }

  bool addInstSelector() override;
};

Reloc::Model getEffectiveRelocModel(const Triple &TT,
                                    Optional<Reloc::Model> RM) {
  if (!RM.hasValue() || *RM == Reloc::DynamicNoPIC)
    return Reloc::Static;

  return *RM;
}

} // namespace

NyuziTargetMachine::NyuziTargetMachine(const Target &T, const Triple &TT,
                                       StringRef CPU, StringRef FS,
                                       const TargetOptions &Options,
                                       Optional<Reloc::Model> RM,
                                       Optional<CodeModel::Model> CM,
                                       CodeGenOpt::Level OL, bool JIT)
    : LLVMTargetMachine(T, "e-m:e-p:32:32", TT, CPU, FS, Options,
                        getEffectiveRelocModel(TT, RM),
                        getEffectiveCodeModel(CM, CodeModel::Medium), OL),
      TLOF(make_unique<NyuziTargetObjectFile>()),
      Subtarget(TT, CPU, FS, *this) {
  initAsmInfo();
}

TargetPassConfig *NyuziTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new NyuziPassConfig(*this, PM);
}

bool NyuziPassConfig::addInstSelector() {
  addPass(createNyuziISelDag(getNyuziTargetMachine()));
  return false;
}

TargetTransformInfo NyuziTargetMachine::getTargetTransformInfo(const Function &F) {
  return TargetTransformInfo(NyuziTTIImpl(this, F));
}
