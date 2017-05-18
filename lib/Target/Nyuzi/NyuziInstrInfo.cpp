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
#include "MCTargetDesc/NyuziMCTargetDesc.h"
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

namespace {
bool isUncondBranchOpcode(int opc) { return opc == Nyuzi::B; }

bool isCondBranchOpcode(int opc) {
  return opc == Nyuzi::BNZ || opc == Nyuzi::BZ;

  // BALL/BNALL/etc. can't be analyzed
}

} // namespace

NyuziInstrInfo::NyuziInstrInfo(NyuziSubtarget &ST)
    : NyuziGenInstrInfo(Nyuzi::ADJCALLSTACKDOWN, Nyuzi::ADJCALLSTACKUP), RI() {}

/// isLoadFromStackSlot - If the specified machine instruction is a direct
/// load from a stack slot, return the virtual or physical register number of
/// the destination along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than loading from the stack slot.
unsigned NyuziInstrInfo::isLoadFromStackSlot(const MachineInstr &MI,
                                             int &FrameIndex) const {
  if (MI.getOpcode() == Nyuzi::LW || MI.getOpcode() == Nyuzi::BLOCK_LOADI) {
    if (MI.getOperand(1).isFI() && MI.getOperand(2).isImm() &&
        MI.getOperand(2).getImm() == 0) {
      FrameIndex = MI.getOperand(1).getIndex();
      return MI.getOperand(0).getReg();
    }
  }

  return 0;
}

/// isStoreToStackSlot - If the specified machine instruction is a direct
/// store to a stack slot, return the virtual or physical register number of
/// the source reg along with the FrameIndex of the loaded stack slot.  If
/// not, return 0.  This predicate must return 0 if the instruction has
/// any side effects other than storing to the stack slot.
unsigned NyuziInstrInfo::isStoreToStackSlot(const MachineInstr &MI,
                                            int &FrameIndex) const {
  if (MI.getOpcode() == Nyuzi::SW || MI.getOpcode() == Nyuzi::BLOCK_STOREI) {
    if (MI.getOperand(1).isFI() && MI.getOperand(2).isImm() &&
        MI.getOperand(2).getImm() == 0) {
      FrameIndex = MI.getOperand(1).getIndex();
      return MI.getOperand(0).getReg();
    }
  }

  return 0;
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

void NyuziInstrInfo::adjustStackPointer(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator MBBI,
                                        const DebugLoc &DL, int Amount) const {
  if (isInt<14>(Amount)) {
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ADDISSI), Nyuzi::SP_REG)
        .addReg(Nyuzi::SP_REG)
        .addImm(Amount);
  } else {
    unsigned int OffsetReg = loadConstant(MBB, MBBI, Amount);
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ADDISSS))
        .addReg(Nyuzi::SP_REG)
        .addReg(Nyuzi::SP_REG)
        .addReg(OffsetReg, RegState::Kill);
  }
}

bool NyuziInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                   MachineBasicBlock *&TBB,
                                   MachineBasicBlock *&FBB,
                                   SmallVectorImpl<MachineOperand> &Cond,
                                   bool AllowModify) const {
  TBB = nullptr;
  FBB = nullptr;

  MachineBasicBlock::iterator I = MBB.end();
  if (I == MBB.begin())
    return false; // Empty blocks are easy.
  --I;

  // Walk backwards from the end of the basic block until the branch is
  // analyzed or we give up.
  while (true) {
    // Flag to be raised on unanalyzeable instructions. This is useful in cases
    // where we want to clean up on the end of the basic block before we bail
    // out.
    bool CantAnalyze = false;

    // Skip over DEBUG values
    while (I->isDebugValue()) {
      if (I == MBB.begin())
        return false;
      --I;
    }

    if (!I->isTerminator())
      break;

    if (isUncondBranchOpcode(I->getOpcode())) {
      TBB = I->getOperand(0).getMBB();
    } else if (isCondBranchOpcode(I->getOpcode())) {
      // Bail out if we encounter multiple conditional branches.
      if (!Cond.empty())
        return true;

      assert(!FBB && "FBB should have been null.");
      // The goto at the end is only the false fall through.
      FBB = TBB;
      TBB = I->getOperand(1).getMBB();

      Cond.push_back(MachineOperand::CreateImm(I->getOpcode()));
      Cond.push_back(I->getOperand(0));
    } else if (I->isReturn()) {
      // Returns can't be analyzed, but we should run cleanup.
      CantAnalyze = true;
    } else {
      // We encountered other unrecognized terminator. Bail out immediately.
      return true;
    }

    // Cleanup code - to be run for unconditional branches and
    //                returns.
    if (isUncondBranchOpcode(I->getOpcode())) {
      // Forget any previous condition branch information - it no longer
      // applies.
      Cond.clear();
      FBB = nullptr;

      // If we can modify the function, delete everything below this
      // unconditional branch.
      if (AllowModify) {
        MachineBasicBlock::iterator DI = std::next(I);
        while (DI != MBB.end()) {
          MachineInstr &InstToDelete = *DI;
          ++DI;
          InstToDelete.eraseFromParent();
        }
      }
    }

    if (CantAnalyze)
      return true;

    if (I == MBB.begin())
      return false;

    --I;
  }

  // We made it past the terminators without bailing out - we must have
  // analyzed this branch successfully.
  return false;
}

unsigned NyuziInstrInfo::insertBranch(MachineBasicBlock &MBB,
                                      MachineBasicBlock *TBB, // If true
                                      MachineBasicBlock *FBB, // If false
                                      ArrayRef<MachineOperand> Cond,
                                      const DebugLoc &DL,
                                      int *BytesAdded) const {
  assert(TBB);
  assert(!BytesAdded && "code size not handled");
  if (FBB) {
    // Has a false block, this is a two way conditional branch
    BuildMI(&MBB, DL, get(Cond[0].getImm())).add(Cond[1]).addMBB(TBB);
    BuildMI(&MBB, DL, get(Nyuzi::B)).addMBB(FBB);
    return 2;
  }

  if (Cond.empty()) {
    // Unconditional branch
    BuildMI(&MBB, DL, get(Nyuzi::B)).addMBB(TBB);
    return 1;
  }

  // One-way conditional branch
  BuildMI(&MBB, DL, get(Cond[0].getImm())).add(Cond[1]).addMBB(TBB);
  return 1;
}

unsigned NyuziInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                      int *BytesRemoved) const {
  assert(!BytesRemoved && "code size not handled");
  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;

    if (I->isDebugValue())
      continue;

    if (!isUncondBranchOpcode(I->getOpcode()) &&
        !isCondBranchOpcode(I->getOpcode()))
      break; // Not a branch

    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}

void NyuziInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator I,
                                 const DebugLoc &DL, unsigned DestReg,
                                 unsigned SrcReg, bool KillSrc) const {
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

// Load constant larger than immediate field (13 bits signed)
unsigned int NyuziInstrInfo::loadConstant(MachineBasicBlock &MBB,
                                          MachineBasicBlock::iterator MBBI,
                                          int Value) const {

  MachineRegisterInfo &RegInfo = MBB.getParent()->getRegInfo();
  DebugLoc DL = MBBI->getDebugLoc();
  unsigned Reg = RegInfo.createVirtualRegister(&Nyuzi::GPR32RegClass);

  if (!isInt<24>(Value))
    report_fatal_error("NyuziInstrInfo::loadConstant: value out of range");

  BuildMI(MBB, MBBI, DL, get(Nyuzi::MOVEHI)).addReg(Reg, RegState::Define)
    .addImm((Value >> 13) & 0x7ffff);
  if ((Value & 0x1fff) != 0) {
    // Load bits 11-0 into register (note we only load 12 bits because we
    // don't want sign extension)
    BuildMI(MBB, MBBI, DL, get(Nyuzi::ORSSI))
        .addReg(Reg, RegState::Define)
        .addReg(Reg)
        .addImm(Value & 0x1fff);
  }

  return Reg;
}

MachineMemOperand *
NyuziInstrInfo::getMemOperand(MachineBasicBlock &MBB, int FI,
                              MachineMemOperand::Flags Flags) const {
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  unsigned Align = MFI.getObjectAlignment(FI);

  return MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(MF, FI),
                                 Flags, MFI.getObjectSize(FI), Align);
}
