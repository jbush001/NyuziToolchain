//===-- VectorProcMCTargetDesc.cpp - VectorProc Target Descriptions -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides VectorProc specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "VectorProcMCTargetDesc.h"
#include "VectorProcMCAsmInfo.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "VectorProcGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "VectorProcGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "VectorProcGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createVectorProcMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitVectorProcMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createVectorProcMCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitVectorProcMCRegisterInfo(X, SP::I7);
  return X;
}

static MCSubtargetInfo *createVectorProcMCSubtargetInfo(StringRef TT, StringRef CPU,
                                                   StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitVectorProcMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCCodeGenInfo *createVectorProcMCCodeGenInfo(StringRef TT, Reloc::Model RM,
                                               CodeModel::Model CM,
                                               CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

extern "C" void LLVMInitializeVectorProcTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfo<VectorProcELFMCAsmInfo> X(TheVectorProcTarget);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheVectorProcTarget,
                                       createVectorProcMCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheVectorProcTarget, createVectorProcMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheVectorProcTarget, createVectorProcMCRegisterInfo);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheVectorProcTarget,
                                          createVectorProcMCSubtargetInfo);
}
