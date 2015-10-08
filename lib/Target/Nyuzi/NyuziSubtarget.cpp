//===-- NyuziSubtarget.cpp - Nyuzi Subtarget Information  ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the nyuzi specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "NyuziSubtarget.h"
#include "Nyuzi.h"
#include "NyuziTargetMachine.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#define DEBUG_TYPE "nyuzi-subtarget"
#include "NyuziGenSubtargetInfo.inc"

using namespace llvm;

void NyuziSubtarget::anchor() {}

NyuziSubtarget::NyuziSubtarget(const Triple &TT, const std::string &CPU,
                               const std::string &FS,
                               const NyuziTargetMachine &TM)
    : NyuziGenSubtargetInfo(TT, CPU, FS),
      InstrInfo(NyuziInstrInfo::create(*this)),
      TLInfo(NyuziTargetLowering::create(TM, *this)), TSInfo(),
      FrameLowering(NyuziFrameLowering::create(*this)) {

  // If the CPU name is empty, a number of other things will not work correctly
  // in subtle ways.
  assert(!CPU.empty());

  InstrItins = getInstrItineraryForCPU(CPU);
  assert(!InstrItins.isEmpty());

  // Parse features string.
  ParseSubtargetFeatures(CPU, FS);
}
