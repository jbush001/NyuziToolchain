//===- NyuziFrameLowering.h - Define frame lowering for Nyuzi --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIFRAMELOWERING_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIFRAMELOWERING_H

#include "Nyuzi.h"
#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {
class NyuziSubtarget;

class NyuziFrameLowering : public TargetFrameLowering {
public:
  explicit NyuziFrameLowering(const NyuziSubtarget &ST)
      : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 64, 0, 64) {}

  void emitPrologue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const override;
  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;
  void determineCalleeSaves(MachineFunction &MF, BitVector &SavedRegs,
                            RegScavenger *RS) const override;
  bool hasFP(const MachineFunction &MF) const override;
  bool hasReservedCallFrame(const MachineFunction &MF) const override;

private:
  uint64_t getWorstCaseStackSize(const MachineFunction &MF) const;
};

} // namespace llvm

#endif
