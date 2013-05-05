//===-- VectorProcRegisterInfo.cpp - VECTORPROC Register Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the VECTORPROC implementation of the TargetRegisterInfo class.
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

#define GET_REGINFO_TARGET_DESC
#include "VectorProcGenRegisterInfo.inc"

using namespace llvm;

VectorProcRegisterInfo::VectorProcRegisterInfo(VectorProcSubtarget &st,
                                     const TargetInstrInfo &tii)
  : VectorProcGenRegisterInfo(SP::S28), Subtarget(st), TII(tii) {
}

const uint16_t* VectorProcRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF)
                                                                         const {
  static const uint16_t CalleeSavedRegs[] = { 0 };
  return CalleeSavedRegs;
}

BitVector VectorProcRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  return Reserved;
}

const TargetRegisterClass*
VectorProcRegisterInfo::getPointerRegClass(const MachineFunction &MF,
                                      unsigned Kind) const {
  return &SP::ScalarRegRegClass;
}

void
VectorProcRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                       int SPAdj, unsigned FIOperandNum,
                                       RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  DebugLoc dl = MI.getDebugLoc();
  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  // Addressable stack objects are accessed using neg. offsets from %fp
  MachineFunction &MF = *MI.getParent()->getParent();
  int64_t Offset = MF.getFrameInfo()->getObjectOffset(FrameIndex) +
                   MI.getOperand(FIOperandNum + 1).getImm() +
                   Subtarget.getStackPointerBias();

  // Replace frame index with a frame pointer reference.
  if (Offset >= -4096 && Offset <= 4095) {
    // If the offset is small enough to fit in the immediate field, directly
    // encode it.
    MI.getOperand(FIOperandNum).ChangeToRegister(SP::S29, false);
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
  } else {
		// XXX for large indices, need to load indirectly. Look at ARM.
  }
}

unsigned VectorProcRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return SP::S29;
}

unsigned VectorProcRegisterInfo::getEHExceptionRegister() const {
  llvm_unreachable("What is the exception register");
}

unsigned VectorProcRegisterInfo::getEHHandlerRegister() const {
  llvm_unreachable("What is the exception handler register");
}
