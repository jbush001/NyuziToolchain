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
  : VectorProcGenRegisterInfo(SP::FP_REG), Subtarget(st), TII(tii) {
}

const uint16_t* VectorProcRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF)
                                                                         const {
  return VectorProcCSR_SaveList;
}

const uint32_t* VectorProcRegisterInfo::getCallPreservedMask(CallingConv::ID) const {
    return VectorProcCSR_RegMask;
}


BitVector VectorProcRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  Reserved.set(SP::SP_REG);
  Reserved.set(SP::LINK_REG);
  Reserved.set(SP::PC_REG);
  Reserved.set(SP::FP_REG);
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
                                       RegScavenger *RS) const 
{
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
		MI.getOperand(FIOperandNum).ChangeToRegister(SP::FP_REG, false);
		MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
	} else {
		// XXX for large indices, need to load indirectly. Look at ARM.
		llvm_unreachable("frame index out of bounds, not implemented");
	}
}

unsigned VectorProcRegisterInfo::getFrameRegister(const MachineFunction &MF) const 
{
	return SP::FP_REG;
}

unsigned VectorProcRegisterInfo::getEHExceptionRegister() const 
{
	llvm_unreachable("What is the exception register");
}

unsigned VectorProcRegisterInfo::getEHHandlerRegister() const 
{
	llvm_unreachable("What is the exception handler register");
}
