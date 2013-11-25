//===-- VectorProcInstrInfo.cpp - VectorProc Instruction Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the VectorProc implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "VectorProcInstrInfo.h"
#include "VectorProc.h"
#include "VectorProcMachineFunctionInfo.h"
#include "VectorProcSubtarget.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/Debug.h"
#include "VectorProcRegisterInfo.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "VectorProcGenInstrInfo.inc"

using namespace llvm;

VectorProcInstrInfo::VectorProcInstrInfo(VectorProcSubtarget &ST)
  : VectorProcGenInstrInfo(VectorProc::ADJCALLSTACKDOWN, VectorProc::ADJCALLSTACKUP),
    RI(ST, *this) {
}

/// isLoadFromStackSlot - If the specified machine instruction is a direct
/// load from a stack slot, return the virtual or physical register number of
/// the destination along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than loading from the stack slot.
unsigned VectorProcInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
    int &FrameIndex) const {
  if (MI->getOpcode() == VectorProc::LW
      || MI->getOpcode() == VectorProc::BLOCK_LOADI) {
    if (MI->getOperand(1).isFI() && MI->getOperand(2).isImm() &&
        MI->getOperand(2).getImm() == 0) {
      FrameIndex = MI->getOperand(1).getIndex();
      return MI->getOperand(0).getReg();
    }
  }

  return 0;
}

/// isStoreToStackSlot - If the specified machine instruction is a direct
/// store to a stack slot, return the virtual or physical register number of
/// the source reg along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than storing to the stack slot.
unsigned VectorProcInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
    int &FrameIndex) const {
  if (MI->getOpcode() == VectorProc::SW
      || MI->getOpcode() == VectorProc::BLOCK_STOREI) {
    if (MI->getOperand(1).isFI() && MI->getOperand(2).isImm() &&
        MI->getOperand(2).getImm() == 0) {
      FrameIndex = MI->getOperand(1).getIndex();
      return MI->getOperand(0).getReg();
    }
  }

  return 0;
}

MachineInstr *
VectorProcInstrInfo::emitFrameIndexDebugValue(MachineFunction &MF,
    int FrameIx,
    uint64_t Offset,
    const MDNode *MDPtr,
    DebugLoc dl) const {
  MachineInstrBuilder MIB = BuildMI(MF, dl, get(VectorProc::DBG_VALUE))
                            .addFrameIndex(FrameIx).addImm(0).addImm(Offset).addMetadata(MDPtr);

  return &*MIB;
}


bool VectorProcInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                                        MachineBasicBlock *&TBB,
                                        MachineBasicBlock *&FBB,
                                        SmallVectorImpl<MachineOperand> &Cond,
                                        bool AllowModify) const
{
  MachineBasicBlock::iterator I = MBB.end();
  MachineBasicBlock::iterator UnCondBrIter = MBB.end();
  while (I != MBB.begin()) {
    --I;

    if (I->isDebugValue())
      continue;

    // When we see a non-terminator, we are done.
    if (!isUnpredicatedTerminator(I))
      break;

    // Terminator is not a branch.
    if (!I->isBranch())
      return true;

    // Handle Unconditional branches.
    if (I->getOpcode() == VectorProc::GOTO) {
      UnCondBrIter = I;

      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      while (llvm::next(I) != MBB.end())
        llvm::next(I)->eraseFromParent();

      FBB = 0;
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = 0;
        I->eraseFromParent();
        I = MBB.end();
        UnCondBrIter = MBB.end();
        continue;
      }

      TBB = I->getOperand(0).getMBB();
      continue;
    }

    return true;
  }

  return false;
}

unsigned
VectorProcInstrInfo::InsertBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *TBB,	// If true
                                  MachineBasicBlock *FBB,	// If false
                                  const SmallVectorImpl<MachineOperand> &Cond,
                                  DebugLoc dl) const
{
  assert(TBB);
  if (FBB)
  {
    // Has a false block, this is a two way conditional branch
    BuildMI(&MBB, dl, get(VectorProc::BTRUE)).addMBB(TBB);
    BuildMI(&MBB, dl, get(VectorProc::GOTO)).addMBB(FBB);
    return 2;
  }

  if (Cond.empty())
  {
    // Unconditional branch
    BuildMI(&MBB, dl, get(VectorProc::GOTO)).addMBB(TBB);
    return 1;
  }

  // One-way conditional branch
  BuildMI(&MBB, dl, get(VectorProc::BTRUE)).addMBB(TBB);
  return 1;
}

unsigned VectorProcInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const
{
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;
  while (I != MBB.begin()) {
    --I;

    if (I->isDebugValue())
      continue;

    if (I->getOpcode() != VectorProc::GOTO
        && I->getOpcode() != VectorProc::BTRUE
        && I->getOpcode() != VectorProc::BFALSE)
      break; // Not a branch

    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }
  return Count;
}

void VectorProcInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                      MachineBasicBlock::iterator I, DebugLoc DL,
                                      unsigned DestReg, unsigned SrcReg,
                                      bool KillSrc) const
{
  bool destIsScalar = VectorProc::ScalarRegRegClass.contains(DestReg);
  bool srcIsScalar = VectorProc::ScalarRegRegClass.contains(SrcReg);
  unsigned operation;

  if (destIsScalar && srcIsScalar)
    operation = VectorProc::MOVESS;
  else if (!destIsScalar && srcIsScalar)
    operation = VectorProc::MOVEVSI;
  else if (!destIsScalar && !srcIsScalar)
    operation = VectorProc::MOVEVV;
  else
    llvm_unreachable("unsupported physical reg copy type");

  BuildMI(MBB, I, DL, get(operation), DestReg).addReg(SrcReg,
      getKillRegState(KillSrc));
}

MachineMemOperand *
VectorProcInstrInfo::GetMemOperand(MachineBasicBlock &MBB, int FI,
                                   unsigned Flag) const
{
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  unsigned Align = MFI.getObjectAlignment(FI);

  return MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FI), Flag,
                                 MFI.getObjectSize(FI), Align);
}

void VectorProcInstrInfo::
storeRegToStack(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                unsigned SrcReg, bool isKill, int FI,
                const TargetRegisterClass *RC, const TargetRegisterInfo *TRI,
                int64_t Offset) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  MachineMemOperand *MMO = GetMemOperand(MBB, FI, MachineMemOperand::MOStore);
  unsigned Opc = 0;

  if (VectorProc::ScalarRegRegClass.hasSubClassEq(RC))
    Opc = VectorProc::SW;
  else if (VectorProc::VectorRegRegClass.hasSubClassEq(RC))
    Opc = VectorProc::BLOCK_STOREI;
  else
    llvm_unreachable("unknown register class in storeRegToStack");

  BuildMI(MBB, I, DL, get(Opc)).addReg(SrcReg, getKillRegState(isKill))
  .addFrameIndex(FI).addImm(Offset).addMemOperand(MMO);
}

void VectorProcInstrInfo::
loadRegFromStack(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                 unsigned DestReg, int FI, const TargetRegisterClass *RC,
                 const TargetRegisterInfo *TRI, int64_t Offset) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  MachineMemOperand *MMO = GetMemOperand(MBB, FI, MachineMemOperand::MOLoad);
  unsigned Opc = 0;

  if (VectorProc::ScalarRegRegClass.hasSubClassEq(RC))
    Opc = VectorProc::LW;
  else if (VectorProc::VectorRegRegClass.hasSubClassEq(RC))
    Opc = VectorProc::BLOCK_LOADI;
  else
    llvm_unreachable("unknown register class in storeRegToStack");

  BuildMI(MBB, I, DL, get(Opc), DestReg).addFrameIndex(FI).addImm(Offset)
  .addMemOperand(MMO);
}
