//===-- NyuziInstrInfo.h - Nyuzi Instruction Information --------*-
// C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Nyuzi implementation of the TargetInstrInfo
// class.
//
//===----------------------------------------------------------------------===//

#ifndef NYUZIINSTRUCTIONINFO_H
#define NYUZIINSTRUCTIONINFO_H

#include "NyuziRegisterInfo.h"
#include "llvm/Target/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "NyuziGenInstrInfo.inc"

namespace llvm {

class NyuziInstrInfo : public NyuziGenInstrInfo {
public:
  explicit NyuziInstrInfo(NyuziSubtarget &ST);

  static const NyuziInstrInfo *create(NyuziSubtarget &ST);

  const NyuziRegisterInfo &getRegisterInfo() const { return RI; }

  /// isLoadFromStackSlot - If the specified machine instruction is a direct
  /// load from a stack slot, return the virtual or physical register number of
  /// the destination along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than loading from the stack slot.
  virtual unsigned isLoadFromStackSlot(const MachineInstr *MI,
                                       int &FrameIndex) const override;

  /// isStoreToStackSlot - If the specified machine instruction is a direct
  /// store to a stack slot, return the virtual or physical register number of
  /// the source reg along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than storing to the stack slot.
  virtual unsigned isStoreToStackSlot(const MachineInstr *MI,
                                      int &FrameIndex) const override;

  virtual bool AnalyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                             MachineBasicBlock *&FBB,
                             SmallVectorImpl<MachineOperand> &Cond,
                             bool AllowModify = false) const override;

  virtual unsigned RemoveBranch(MachineBasicBlock &MBB) const override;

  virtual unsigned InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                                MachineBasicBlock *FBB,
                                ArrayRef<MachineOperand> Cond,
                                DebugLoc DL) const override;

  virtual void copyPhysReg(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator I, DebugLoc DL,
                           unsigned DestReg, unsigned SrcReg,
                           bool KillSrc) const override;

  virtual void
  storeRegToStackSlot(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                      unsigned SrcReg, bool isKill, int FrameIndex,
                      const TargetRegisterClass *RC,
                      const TargetRegisterInfo *TRI) const override;

  virtual void
  loadRegFromStackSlot(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                       unsigned DestReg, int FrameIndex,
                       const TargetRegisterClass *RC,
                       const TargetRegisterInfo *TRI) const override;

  void adjustStackPointer(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                          int Amount) const;

private:
  unsigned int loadConstant(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MBBI, int Amount) const;

  MachineMemOperand *getMemOperand(MachineBasicBlock &MBB, int FI,
                                   unsigned Flag) const;
  const NyuziRegisterInfo RI;
};
}

#endif
