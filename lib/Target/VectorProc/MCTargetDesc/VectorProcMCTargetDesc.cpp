//===-- VectorProcMCTargetDesc.cpp - VectorProc Target Descriptions
//-----------------===//
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
#include "InstPrinter/VectorProcInstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCELFStreamer.h"
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
  InitVectorProcMCRegisterInfo(X, VectorProc::FP_REG);
  return X;
}

static MCSubtargetInfo *
createVectorProcMCSubtargetInfo(StringRef TT, StringRef CPU, StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitVectorProcMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCCodeGenInfo *createVectorProcMCCodeGenInfo(StringRef TT,
                                                    Reloc::Model RM,
                                                    CodeModel::Model CM,
                                                    CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCAsmInfo *createVectorProcMCAsmInfo(const MCRegisterInfo &MRI,
                                            StringRef TT) {
  return new VectorProcMCAsmInfo(TT);
}

static MCStreamer *createVectorProcMCStreamer(const Target &T, StringRef TT,
                                              MCContext &Ctx, MCAsmBackend &MAB,
                                              raw_ostream &_OS,
                                              MCCodeEmitter *_Emitter,
                                              bool RelaxAll, bool NoExecStack) {
  Triple TheTriple(TT);
  if (TheTriple.isOSDarwin()) {
    llvm_unreachable("VectorProc does not support Darwin MACH-O format");
  }
  if (TheTriple.isOSWindows()) {
    llvm_unreachable("VectorProc does not support Windows COFF format");
  }
  MCTargetStreamer *streamer = new MCTargetStreamer;
  return createELFStreamer(Ctx, streamer, MAB, _OS, _Emitter, RelaxAll,
                           NoExecStack);
}

static MCInstPrinter *
createVectorProcMCInstPrinter(const Target &T, unsigned SyntaxVariant,
                              const MCAsmInfo &MAI, const MCInstrInfo &MII,
                              const MCRegisterInfo &MRI,
                              const MCSubtargetInfo &STI) {
  return new VectorProcInstPrinter(MAI, MII, MRI);
}

extern "C" void LLVMInitializeVectorProcTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn A(TheVectorProcTarget, createVectorProcMCAsmInfo);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheVectorProcTarget,
                                        createVectorProcMCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheVectorProcTarget,
                                      createVectorProcMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheVectorProcTarget,
                                    createVectorProcMCRegisterInfo);

  TargetRegistry::RegisterMCCodeEmitter(TheVectorProcTarget,
                                        createVectorProcMCCodeEmitter);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheVectorProcTarget,
                                          createVectorProcMCSubtargetInfo);

  // Register the ASM Backend
  TargetRegistry::RegisterMCAsmBackend(TheVectorProcTarget,
                                       createVectorProcAsmBackend);

  // Register the object streamer
  TargetRegistry::RegisterMCObjectStreamer(TheVectorProcTarget,
                                           createVectorProcMCStreamer);

  // MC instruction printer
  TargetRegistry::RegisterMCInstPrinter(TheVectorProcTarget,
                                        createVectorProcMCInstPrinter);

}
