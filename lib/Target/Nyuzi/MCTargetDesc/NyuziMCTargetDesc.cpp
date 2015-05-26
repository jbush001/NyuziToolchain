//===-- NyuziMCTargetDesc.cpp - Nyuzi Target Descriptions
//-----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides Nyuzi specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "NyuziMCTargetDesc.h"
#include "NyuziMCAsmInfo.h"
#include "InstPrinter/NyuziInstPrinter.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCELFStreamer.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "NyuziGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "NyuziGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "NyuziGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createNyuziMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitNyuziMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createNyuziMCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitNyuziMCRegisterInfo(X, Nyuzi::RA_REG);
  return X;
}

static MCSubtargetInfo *
createNyuziMCSubtargetInfo(StringRef TT, StringRef CPU, StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitNyuziMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCCodeGenInfo *createNyuziMCCodeGenInfo(StringRef TT,
                                                    Reloc::Model RM,
                                                    CodeModel::Model CM,
                                                    CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCAsmInfo *createNyuziMCAsmInfo(const MCRegisterInfo &MRI,
                                            StringRef TT) {
  return new NyuziMCAsmInfo(TT);
}

static MCStreamer *createNyuziMCStreamer(const Triple &T, MCContext &Context,
                                         MCAsmBackend &MAB, raw_ostream &OS,
                                         MCCodeEmitter *Emitter, bool RelaxAll) {
  return createELFStreamer(Context, MAB, OS, Emitter, RelaxAll);
}

static MCInstPrinter *
createNyuziMCInstPrinter(const Triple &T,
                         unsigned SyntaxVariant,
                         const MCAsmInfo &MAI,
                         const MCInstrInfo &MII,
                         const MCRegisterInfo &MRI) {
  return new NyuziInstPrinter(MAI, MII, MRI);
}

extern "C" void LLVMInitializeNyuziTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn A(TheNyuziTarget, createNyuziMCAsmInfo);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheNyuziTarget,
                                        createNyuziMCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheNyuziTarget,
                                      createNyuziMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheNyuziTarget,
                                    createNyuziMCRegisterInfo);

  TargetRegistry::RegisterMCCodeEmitter(TheNyuziTarget,
                                        createNyuziMCCodeEmitter);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheNyuziTarget,
                                          createNyuziMCSubtargetInfo);

  // Register the ASM Backend
  TargetRegistry::RegisterMCAsmBackend(TheNyuziTarget,
                                       createNyuziAsmBackend);

  // Register the object streamer
  TargetRegistry::RegisterELFStreamer(TheNyuziTarget,
                                      createNyuziMCStreamer);

  // MC instruction printer
  TargetRegistry::RegisterMCInstPrinter(TheNyuziTarget,
                                        createNyuziMCInstPrinter);

}
