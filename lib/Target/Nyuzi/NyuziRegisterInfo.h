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

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIREGISTERINFO_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIREGISTERINFO_H

#include "llvm/CodeGen/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "NyuziGenRegisterInfo.inc"

namespace llvm {

class NyuziSubtarget;

struct NyuziRegisterInfo : public NyuziGenRegisterInfo {
public:
  NyuziRegisterInfo();
  const uint16_t *
  getCalleeSavedRegs(const MachineFunction *MF = 0) const override;
  const uint32_t *getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID) const override;
  BitVector getReservedRegs(const MachineFunction &MF) const override;
  const TargetRegisterClass *getPointerRegClass(const MachineFunction &MF,
                                                unsigned Kind) const override;
  void eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *) const override;
  unsigned getFrameRegister(const MachineFunction &MF) const override;
  bool requiresRegisterScavenging(const MachineFunction &MF) const override;
  bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;
  bool requiresFrameIndexScavenging(const MachineFunction &MF) const override;
};

} // end namespace llvm

#endif
