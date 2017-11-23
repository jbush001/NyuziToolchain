//===-- NyuziInstrInfo.h - Nyuzi Instruction Information --------*- C++ -*-===//
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

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIINSTRINFO_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIINSTRINFO_H

#include "NyuziRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "NyuziGenInstrInfo.inc"

namespace llvm {

class NyuziInstrInfo : public NyuziGenInstrInfo {
public:
  explicit NyuziInstrInfo(NyuziSubtarget &ST);

  const NyuziRegisterInfo &getRegisterInfo() const { return RI; }

  /// isLoadFromStackSlot - If the specified machine instruction is a direct
  /// load from a stack slot, return the virtual or physical register number of
  /// the destination along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than loading from the stack slot.
  unsigned isLoadFromStackSlot(const MachineInstr &MI,
                               int &FrameIndex) const override;

  /// isStoreToStackSlot - If the specified machine instruction is a direct
  /// store to a stack slot, return the virtual or physical register number of
  /// the source reg along with the FrameIndex of the loaded stack slot.  If
  /// not, return 0.  This predicate must return 0 if the instruction has
  /// any side effects other than storing to the stack slot.
  unsigned isStoreToStackSlot(const MachineInstr &MI,
                              int &FrameIndex) const override;
  void loadRegFromStackSlot(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MBBI, unsigned DestReg,
                            int FrameIndex, const TargetRegisterClass *RC,
                            const TargetRegisterInfo *TRI) const override;
  void storeRegToStackSlot(MachineBasicBlock &MBB,
                           MachineBasicBlock::iterator MBBI, unsigned SrcReg,
                           bool isKill, int FrameIndex,
                           const TargetRegisterClass *RC,
                           const TargetRegisterInfo *TRI) const override;
  void adjustStackPointer(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                          const DebugLoc &DL, int Amount) const;
  bool analyzeBranch(MachineBasicBlock &MBB, MachineBasicBlock *&TBB,
                     MachineBasicBlock *&FBB,
                     SmallVectorImpl<MachineOperand> &Cond,
                     bool AllowModify = false) const override;
  unsigned insertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                        MachineBasicBlock *FBB, ArrayRef<MachineOperand> Cond,
                        const DebugLoc &DL, int *BytesAdded) const override;
  unsigned removeBranch(MachineBasicBlock &MBB,
                        int *BytesRemoved) const override;
  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                   const DebugLoc &DL, unsigned DestReg, unsigned SrcReg,
                   bool KillSrc) const override;

private:
  unsigned int loadConstant(MachineBasicBlock &MBB,
                            MachineBasicBlock::iterator MBBI, int Amount) const;
  MachineMemOperand *getMemOperand(MachineBasicBlock &MBB, int FI,
                                   MachineMemOperand::Flags) const;
  const NyuziRegisterInfo RI;
};

} // namespace llvm

#endif
