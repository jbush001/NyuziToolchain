//===-- NyuziRegisterInfo.h - Nyuzi Register Information Impl -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Nyuzi implementation of the TargetRegisterInfo
// class.
//
//===----------------------------------------------------------------------===//

#ifndef NYUZIREGISTERINFO_H
#define NYUZIREGISTERINFO_H

#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "NyuziGenRegisterInfo.inc"

namespace llvm {

class NyuziSubtarget;
class TargetInstrInfo;
class Type;

struct NyuziRegisterInfo : public NyuziGenRegisterInfo {
  NyuziSubtarget &Subtarget;
  const TargetInstrInfo &TII;

  NyuziRegisterInfo(NyuziSubtarget &st, const TargetInstrInfo &tii);
  virtual const uint16_t *
  getCalleeSavedRegs(const MachineFunction *MF = 0) const override;
  virtual const uint32_t *getCallPreservedMask(const MachineFunction &MF,
                                               CallingConv::ID) const override;
  virtual BitVector getReservedRegs(const MachineFunction &MF) const override;
  virtual const TargetRegisterClass *
  getPointerRegClass(const MachineFunction &MF, unsigned Kind) const override;
  virtual void eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                                   unsigned FIOperandNum,
                                   RegScavenger *) const override;
  virtual unsigned getFrameRegister(const MachineFunction &MF) const override;
  virtual bool
  requiresRegisterScavenging(const MachineFunction &MF) const override;
  virtual bool
  trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;
  virtual bool
  requiresFrameIndexScavenging(const MachineFunction &MF) const override;
};

} // end namespace llvm

#endif
