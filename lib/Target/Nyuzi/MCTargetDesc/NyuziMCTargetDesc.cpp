//===-- NyuziMCTargetDesc.cpp - Nyuzi Target Descriptions  ---------------===//
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
#include "InstPrinter/NyuziInstPrinter.h"
#include "NyuziMCAsmInfo.h"
#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCInstrAnalysis.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
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

static MCRegisterInfo *createNyuziMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitNyuziMCRegisterInfo(X, Nyuzi::RA_REG);
  return X;
}

static MCSubtargetInfo *
createNyuziMCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  return createNyuziMCSubtargetInfoImpl(TT, CPU, FS);
}

static MCAsmInfo *createNyuziMCAsmInfo(const MCRegisterInfo &MRI,
                                       const Triple &TT) {
  MCAsmInfo *MAI = new NyuziMCAsmInfo(TT);

  // Put an instruction into the common information entry (CIE), shared
  // by all frame description entries (FDE), which indicates the stack
  // pointer register (r30) is used to find the canonical frame address (CFA).
  unsigned SP = MRI.getDwarfRegNum(Nyuzi::SP_REG, true);
  MCCFIInstruction Inst = MCCFIInstruction::createDefCfa(nullptr, SP, 0);
  MAI->addInitialFrameState(Inst);

  return MAI;
}

static MCStreamer *createNyuziMCStreamer(const Triple &T, MCContext &Context,
                                         std::unique_ptr<MCAsmBackend> &&MAB,
                                         std::unique_ptr<MCObjectWriter> &&OW,
                                         std::unique_ptr<MCCodeEmitter> &&Emitter,
                                         bool RelaxAll) {
  return createELFStreamer(Context, std::move(MAB), std::move(OW),
                           std::move(Emitter), RelaxAll);
}

static MCInstPrinter *createNyuziMCInstPrinter(const Triple &T,
                                               unsigned SyntaxVariant,
                                               const MCAsmInfo &MAI,
                                               const MCInstrInfo &MII,
                                               const MCRegisterInfo &MRI) {
  return new NyuziInstPrinter(MAI, MII, MRI);
}

namespace {

class NyuziMCInstrAnalysis : public MCInstrAnalysis {
public:
  explicit NyuziMCInstrAnalysis(const MCInstrInfo *Info) : MCInstrAnalysis(Info) {}

  bool evaluateBranch(const MCInst &Inst, uint64_t Addr, uint64_t Size,
                      uint64_t &Target) const override {

    unsigned NumOps = Inst.getNumOperands();
    if (NumOps == 0)
      return false;
    switch (Info->get(Inst.getOpcode()).OpInfo[NumOps - 1].OperandType) {
    case MCOI::OPERAND_UNKNOWN:
    case MCOI::OPERAND_IMMEDIATE:
      Target = Addr + Inst.getOperand(NumOps - 1).getImm();
      return true;
    default:
      return false;
    }
  }
};

} // namespace

static MCInstrAnalysis *createNyuziMCInstrAnalysis(const MCInstrInfo *Info) {
  return new NyuziMCInstrAnalysis(Info);
}

extern "C" void LLVMInitializeNyuziTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn A(TheNyuziTarget, createNyuziMCAsmInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheNyuziTarget, createNyuziMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheNyuziTarget, createNyuziMCRegisterInfo);

  TargetRegistry::RegisterMCCodeEmitter(TheNyuziTarget,
                                        createNyuziMCCodeEmitter);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheNyuziTarget,
                                          createNyuziMCSubtargetInfo);

  // Register the MC instruction analyzer.
  TargetRegistry::RegisterMCInstrAnalysis(TheNyuziTarget,
                                          createNyuziMCInstrAnalysis);

  // Register the ASM Backend
  TargetRegistry::RegisterMCAsmBackend(TheNyuziTarget, createNyuziAsmBackend);

  // Register the object streamer
  TargetRegistry::RegisterELFStreamer(TheNyuziTarget, createNyuziMCStreamer);

  // MC instruction printer
  TargetRegistry::RegisterMCInstPrinter(TheNyuziTarget,
                                        createNyuziMCInstPrinter);
}
