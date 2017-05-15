//===--------- NyuziSubtarget.cpp - Nyuzi Subtarget Information  ----------===//
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

#define DEBUG_TYPE "nyuzi-subtarget"

#include "NyuziSubtarget.h"
#include "Nyuzi.h"
#include "NyuziTargetMachine.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "NyuziGenSubtargetInfo.inc"

using namespace llvm;

void NyuziSubtarget::anchor() {}

NyuziSubtarget::NyuziSubtarget(const Triple &TT, const std::string &CPU,
                               const std::string &FS,
                               const NyuziTargetMachine &TM)
    : NyuziGenSubtargetInfo(TT, CPU, FS),
      InstrInfo(*this),
      TargetLowering(TM, *this),
      FrameLowering(*this) {

  std::string CPUName = CPU;

  // CPUName is empty when invoked from tools like llc
  if (CPUName.empty())
    CPUName = "nyuzi";

  InstrItins = getInstrItineraryForCPU(CPUName);

  // Parse features string.
  ParseSubtargetFeatures(CPUName, FS);
}
