//===-- VectorProcRegisterInfo.cpp - VECTORPROC Register Information
//----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the VECTORPROC implementation of the TargetRegisterInfo
// class.
//
//===----------------------------------------------------------------------===//

#include "VectorProcRegisterInfo.h"
#include "VectorProc.h"
#include "VectorProcSubtarget.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Support/Debug.h"

#define GET_REGINFO_TARGET_DESC
#include "VectorProcGenRegisterInfo.inc"

using namespace llvm;

VectorProcRegisterInfo::VectorProcRegisterInfo(VectorProcSubtarget &st,
                                               const TargetInstrInfo &tii)
    : VectorProcGenRegisterInfo(VectorProc::FP_REG), Subtarget(st), TII(tii) {}

const uint16_t *
VectorProcRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return VectorProcCSR_SaveList;
}

const uint32_t *
VectorProcRegisterInfo::getCallPreservedMask(CallingConv::ID) const {
  return VectorProcCSR_RegMask;
}

BitVector
VectorProcRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(VectorProc::SP_REG);
  Reserved.set(VectorProc::LINK_REG);
  Reserved.set(VectorProc::PC_REG);
  Reserved.set(VectorProc::FP_REG);
  return Reserved;
}

const TargetRegisterClass *
VectorProcRegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                           unsigned Kind) const {
  return &VectorProc::GPR32RegClass;
}

void VectorProcRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                                 int SPAdj,
                                                 unsigned FIOperandNum,
                                                 RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();
  MachineFunction &MF = *MI.getParent()->getParent();
  MachineFrameInfo *MFI = MF.getFrameInfo();

  // Round stack size to multiple of 64, consistent with frame pointer info.
  int stackSize = RoundUpToAlignment(MF.getFrameInfo()->getStackSize(), 
    kVectorProcStackFrameAlign);

  // Frame index is relative to where SP is before it is decremented on
  // entry to the function.  Need to add stackSize to adjust for this.
  int64_t Offset = MF.getFrameInfo()->getObjectOffset(FrameIndex) +
                   MI.getOperand(FIOperandNum + 1).getImm() + stackSize;

  // Determine where callee saved registers live in the frame
  const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();
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
    FrameReg = VectorProc::SP_REG;
  else
    FrameReg = getFrameRegister(MF);

  // Replace frame index with a frame pointer reference.
  if (Offset >= -16384 && Offset <= 16384) {
    // If the offset is small enough to fit in the immediate field, directly
    // encode it.
    MI.getOperand(FIOperandNum).ChangeToRegister(FrameReg, false);
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
  } else {
    // XXX for large indices, need to load indirectly. Look at ARM.
    report_fatal_error("frame index out of bounds, large stack frames not supported");
  }
}

unsigned
VectorProcRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();
  return TFI->hasFP(MF) ? VectorProc::FP_REG : VectorProc::SP_REG;
}
