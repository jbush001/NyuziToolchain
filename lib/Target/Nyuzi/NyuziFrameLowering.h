//===-- NyuziFrameLowering.h - Define frame lowering for Nyuzi --*-
// C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef NYUZIFRAMELOWERING_H
#define NYUZIFRAMELOWERING_H

#include "Nyuzi.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
class NyuziSubtarget;

class NyuziFrameLowering : public TargetFrameLowering {
public:
  static const NyuziFrameLowering *create(const NyuziSubtarget &ST);

  explicit NyuziFrameLowering(const NyuziSubtarget &ST)
      : TargetFrameLowering(TargetFrameLowering::StackGrowsDown, 64, 0, 64) {}

  virtual void emitPrologue(MachineFunction &MF,
                            MachineBasicBlock &MBB) const override;
  virtual void emitEpilogue(MachineFunction &MF,
                            MachineBasicBlock &MBB) const override;
  virtual void
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;
  virtual void determineCalleeSaves(MachineFunction &MF, BitVector &SavedRegs,
                                    RegScavenger *RS) const override;
  virtual bool hasFP(const MachineFunction &MF) const override;
  virtual bool hasReservedCallFrame(const MachineFunction &MF) const override;

private:
  uint64_t getWorstCaseStackSize(const MachineFunction &MF) const;
};

} // End llvm namespace

#endif
