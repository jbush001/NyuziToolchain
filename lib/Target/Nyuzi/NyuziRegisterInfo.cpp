//===------- NyuziRegisterInfo.cpp - Nyuzi Register Information -----------===//
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

#include "NyuziRegisterInfo.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "Nyuzi.h"
#include "NyuziInstrInfo.h"
#include "NyuziSubtarget.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

#define GET_REGINFO_TARGET_DESC
#include "NyuziGenRegisterInfo.inc"

using namespace llvm;

NyuziRegisterInfo::NyuziRegisterInfo() : NyuziGenRegisterInfo(Nyuzi::FP_REG) {}

const uint16_t *
NyuziRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return NyuziCSR_SaveList;
}

const uint32_t *
NyuziRegisterInfo::getCallPreservedMask(const MachineFunction &MF,
                                        CallingConv::ID) const {
  return NyuziCSR_RegMask;
}

BitVector NyuziRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(Nyuzi::SP_REG);
  Reserved.set(Nyuzi::RA_REG);
  Reserved.set(Nyuzi::FP_REG);
  Reserved.set(Nyuzi::GP_REG);
  return Reserved;
}

const TargetRegisterClass *
NyuziRegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                      unsigned Kind) const {
  return &Nyuzi::GPR32RegClass;
}

void NyuziRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator MBBI,
                                            int SPAdj, unsigned FIOperandNum,
                                            RegScavenger *RS) const {

  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *MBBI;
  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();
  MachineFunction &MF = *MI.getParent()->getParent();
  const TargetFrameLowering &TFL = *MF.getSubtarget().getFrameLowering();
  MachineFrameInfo &MFI = MF.getFrameInfo();

  // Round stack size to multiple of 64, consistent with frame pointer info.
  int stackSize = alignTo(MFI.getStackSize(), TFL.getStackAlignment());

  // Frame index is relative to where SP is before it is decremented on
  // entry to the function.  Need to add stackSize to adjust for this.
  int64_t Offset = MF.getFrameInfo().getObjectOffset(FrameIndex) +
                   MI.getOperand(FIOperandNum + 1).getImm() + stackSize;

  // Determine where callee saved registers live in the frame
  const std::vector<CalleeSavedInfo> &CSI = MFI.getCalleeSavedInfo();
  int MinCSFI = 0;
  int MaxCSFI = -1;
  if (CSI.size()) {
    MinCSFI = CSI[0].getFrameIdx();
    MaxCSFI = CSI[CSI.size() - 1].getFrameIdx();
  }

  // When we save callee saved registers (which includes FP), we must use
  // the SP reg, because FP is not set up yet.
  unsigned FrameReg;
  if (FrameIndex >= MinCSFI && FrameIndex <= MaxCSFI)
    FrameReg = Nyuzi::SP_REG;
  else
    FrameReg = getFrameRegister(MF);

  // Replace frame index with a frame pointer reference.
  if (isInt<14>(Offset)) {
    // If the offset is small enough to fit in the immediate field, directly
    // encode it.
    MI.getOperand(FIOperandNum).ChangeToRegister(FrameReg, false);
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
  } else if (isInt<25>(Offset)) {
    DebugLoc DL = MBBI->getDebugLoc();
    MachineBasicBlock &MBB = *MBBI->getParent();
    const NyuziInstrInfo &TII =
        *static_cast<const NyuziInstrInfo *>(MF.getSubtarget().getInstrInfo());

    MachineRegisterInfo &RegInfo = MBB.getParent()->getRegInfo();
    unsigned Reg = RegInfo.createVirtualRegister(&Nyuzi::GPR32RegClass);
    BuildMI(MBB, MBBI, DL, TII.get(Nyuzi::MOVEHI)).addReg(Reg, RegState::Define)
      .addImm((Offset >> 13) & 0x7ffff);
    BuildMI(MBB, MBBI, DL, TII.get(Nyuzi::ADDISSS)).addReg(Reg, RegState::Define)
      .addReg(FrameReg)
      .addReg(Reg);

    MI.getOperand(FIOperandNum).ChangeToRegister(Reg, false, false, true /* isKill */);
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset & 0x1fff);
  } else
    report_fatal_error("frame index out of bounds: frame too large");
}

unsigned NyuziRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  return TFI->hasFP(MF) ? Nyuzi::FP_REG : Nyuzi::SP_REG;
}

bool NyuziRegisterInfo::requiresRegisterScavenging(
    const MachineFunction &MF) const {
  return true;
}

bool NyuziRegisterInfo::trackLivenessAfterRegAlloc(
    const MachineFunction &MF) const {
  return true;
}

bool NyuziRegisterInfo::requiresFrameIndexScavenging(
    const MachineFunction &MF) const {
  return true;
}
