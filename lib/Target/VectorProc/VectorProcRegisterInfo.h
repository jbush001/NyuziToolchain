//===-- VectorProcRegisterInfo.h - VectorProc Register Information Impl ---*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the VectorProc implementation of the TargetRegisterInfo
// class.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCREGISTERINFO_H
#define VECTORPROCREGISTERINFO_H

#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "VectorProcGenRegisterInfo.inc"

namespace llvm {

class VectorProcSubtarget;
class TargetInstrInfo;
class Type;

struct VectorProcRegisterInfo : public VectorProcGenRegisterInfo {
  VectorProcSubtarget &Subtarget;
  const TargetInstrInfo &TII;

  VectorProcRegisterInfo(VectorProcSubtarget &st, const TargetInstrInfo &tii);

  /// Code Generation virtual methods...
  const uint16_t *getCalleeSavedRegs(const MachineFunction *MF = 0) const override;
  const uint32_t *getCallPreservedMask(CallingConv::ID) const override;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  const TargetRegisterClass *getPointerRegClass(const MachineFunction &MF,
                                                unsigned Kind) const override;

  virtual void eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger*) const override;

  // Debug information queries.
  virtual unsigned getFrameRegister(const MachineFunction &MF) const override;
  virtual bool requiresRegisterScavenging(const MachineFunction &MF) const override;
  virtual bool trackLivenessAfterRegAlloc(const MachineFunction &MF) const override;
  virtual bool requiresFrameIndexScavenging(const MachineFunction &MF) const override;

};

} // end namespace llvm

#endif
