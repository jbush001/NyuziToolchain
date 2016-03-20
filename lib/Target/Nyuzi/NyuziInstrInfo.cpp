//===-- NyuziInstrInfo.cpp - Nyuzi Instruction Information ---------------===//
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

#include "NyuziInstrInfo.h"
#include "Nyuzi.h"
#include "NyuziMachineFunctionInfo.h"
#include "NyuziRegisterInfo.h"
#include "NyuziSubtarget.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "NyuziGenInstrInfo.inc"

using namespace llvm;

const NyuziInstrInfo *NyuziInstrInfo::create(NyuziSubtarget &ST) {
  return new NyuziInstrInfo(ST);
}

NyuziInstrInfo::NyuziInstrInfo(NyuziSubtarget &ST)
    : NyuziGenInstrInfo(Nyuzi::ADJCALLSTACKDOWN, Nyuzi::ADJCALLSTACKUP),
      RI() {}

/// isLoadFromStackSlot - If the specified machine instruction is a direct
/// load from a stack slot, return the virtual or physical register number of
/// the destination along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than loading from the stack slot.
unsigned NyuziInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                             int &FrameIndex) const {
  if (MI->getOpcode() == Nyuzi::LW || MI->getOpcode() == Nyuzi::BLOCK_LOADI) {
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
unsigned NyuziInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                            int &FrameIndex) const {
  if (MI->getOpcode() == Nyuzi::SW || MI->getOpcode() == Nyuzi::BLOCK_STOREI) {
    if (MI->getOperand(1).isFI() && MI->getOperand(2).isImm() &&
        MI->getOperand(2).getImm() == 0) {
      FrameIndex = MI->getOperand(1).getIndex();
      return MI->getOperand(0).getReg();
    }
  }

  return 0;
}

bool NyuziInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,
                                   MachineBasicBlock *&TBB,
                                   MachineBasicBlock *&FBB,
                                   SmallVectorImpl<MachineOperand> &Cond,
                                   bool AllowModify) const {
  MachineBasicBlock::iterator I = MBB.end();
  MachineBasicBlock::iterator UnCondBrIter = MBB.end();
  while (I != MBB.begin()) {
    --I;

    if (I->isDebugValue())
      continue;

    // When we see a non-terminator, we are done.
    if (!isUnpredicatedTerminator(*I))
      break;

    // Terminator is not a branch.
    if (!I->isBranch())
      return true;

    // Handle Unconditional branches.
    if (I->getOpcode() == Nyuzi::GOTO) {
      UnCondBrIter = I;

      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      while (std::next(I) != MBB.end())
        std::next(I)->eraseFromParent();

      FBB = nullptr;
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = nullptr;
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

unsigned NyuziInstrInfo::InsertBranch(MachineBasicBlock &MBB,
                                      MachineBasicBlock *TBB, // If true
                                      MachineBasicBlock *FBB, // If false
                                      ArrayRef<MachineOperand> Cond,
                                      DebugLoc DL) const {
  assert(TBB);
  if (FBB) {
    // Has a false block, this is a two way conditional branch
    BuildMI(&MBB, DL, get(Nyuzi::BTRUE)).addMBB(TBB);
    BuildMI(&MBB, DL, get(Nyuzi::GOTO)).addMBB(FBB);
    return 2;
  }

  if (Cond.empty()) {
    // Unconditional branch
    BuildMI(&MBB, DL, get(Nyuzi::GOTO)).addMBB(TBB);
    return 1;
  }

  // One-way conditional branch
  BuildMI(&MBB, DL, get(Nyuzi::BTRUE)).addMBB(TBB);
  return 1;
}

unsigned NyuziInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;
  while (I != MBB.begin()) {
    --I;

    if (I->isDebugValue())
      continue;

    if (I->getOpcode() != Nyuzi::GOTO && I->getOpcode() != Nyuzi::BTRUE &&
        I->getOpcode() != Nyuzi::BFALSE)
      break; // Not a branch

    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }
  return Count;
}

void NyuziInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator I, DebugLoc DL,
                                 unsigned DestReg, unsigned SrcReg,
                                 bool KillSrc) const {
  bool destIsScalar = Nyuzi::GPR32RegClass.contains(DestReg);
  bool srcIsScalar = Nyuzi::GPR32RegClass.contains(SrcReg);
  unsigned operation;

  if (destIsScalar && srcIsScalar)
    operation = Nyuzi::MOVESS;
  else if (!destIsScalar && srcIsScalar)
    operation = Nyuzi::MOVEVSI;
  else if (!destIsScalar && !srcIsScalar)
    operation = Nyuzi::MOVEVV;
  else
    llvm_unreachable("unsupported physical reg copy type");

  BuildMI(MBB, I, DL, get(operation), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc));
}

MachineMemOperand *NyuziInstrInfo::getMemOperand(MachineBasicBlock &MBB, int FI,
                                                 unsigned Flag) const {
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  unsigned Align = MFI.getObjectAlignment(FI);

  return MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(MF, FI),
                                 Flag, MFI.getObjectSize(FI), Align);
}

void NyuziInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                         MachineBasicBlock::iterator MBBI,
                                         unsigned SrcReg, bool isKill,
                                         int FrameIndex,
                                         const TargetRegisterClass *RC,
                                         const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  MachineMemOperand *MMO =
      getMemOperand(MBB, FrameIndex, MachineMemOperand::MOStore);
  unsigned Opc = 0;

  if (Nyuzi::GPR32RegClass.hasSubClassEq(RC))
    Opc = Nyuzi::SW;
  else if (Nyuzi::VR512RegClass.hasSubClassEq(RC))
    Opc = Nyuzi::BLOCK_STOREI;
  else
    llvm_unreachable("unknown register class in storeRegToStack");

  BuildMI(MBB, MBBI, DL, get(Opc))
      .addReg(SrcReg, getKillRegState(isKill))
      .addFrameIndex(FrameIndex)
      .addImm(0)
      .addMemOperand(MMO);
}

void NyuziInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MBBI,
                                          unsigned DestReg, int FrameIndex,
                                          const TargetRegisterClass *RC,
                                          const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (MBBI != MBB.end())
    DL = MBBI->getDebugLoc();

  MachineMemOperand *MMO =
      getMemOperand(MBB, FrameIndex, MachineMemOperand::MOLoad);
  unsigned Opc = 0;

  if (Nyuzi::GPR32RegClass.hasSubClassEq(RC))
    Opc = Nyuzi::LW;
  else if (Nyuzi::VR512RegClass.hasSubClassEq(RC))
    Opc = Nyuzi::BLOCK_LOADI;
  else
    llvm_unreachable("unknown register class in storeRegToStack");

  BuildMI(MBB, MBBI, DL, get(Opc), DestReg)
      .addFrameIndex(FrameIndex)
      .addImm(0)
      .addMemOperand(MMO);
}

void NyuziInstrInfo::adjustStackPointer(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator MBBI,
                                        int Amount) const {
  DebugLoc DL(MBBI->getDebugLoc());
  if (isInt<13>(Amount)) {
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ADDISSI), Nyuzi::SP_REG)
        .addReg(Nyuzi::SP_REG)
        .addImm(Amount);
  } else {
    unsigned int OffsetReg = loadConstant(MBB, MBBI, Amount);
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ADDISSS))
        .addReg(Nyuzi::SP_REG)
        .addReg(Nyuzi::SP_REG)
        .addReg(OffsetReg);
  }
}

// Load constant larger than immediate field (13 bits signed)
unsigned int NyuziInstrInfo::loadConstant(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MBBI,
                                          int Value) const {

  MachineRegisterInfo &RegInfo = MBB.getParent()->getRegInfo();
  DebugLoc DL = MBBI->getDebugLoc();
  unsigned Reg = RegInfo.createVirtualRegister(&Nyuzi::GPR32RegClass);

  if (!isInt<24>(Value))
    report_fatal_error("NyuziInstrInfo::loadConstant: value out of range");

  BuildMI(MBB, MBBI, DL, get(Nyuzi::MOVESimm), Reg).addImm(Value >> 12);
  BuildMI(MBB, MBBI, DL, get(Nyuzi::SLLSSI)).addReg(Reg).addReg(Reg).addImm(12);

  if ((Value & 0xfff) != 0) {
    // Load bits 11-0 into register (note we only load 12 bits because we
    // don't want sign extension)
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ORSSI))
        .addReg(Reg)
        .addReg(Reg)
        .addImm(Value & 0xfff);
  }

  return Reg;
}
