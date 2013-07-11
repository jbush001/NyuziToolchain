//===-- VectorProcFrameLowering.cpp - VectorProc Frame Information ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the VectorProc implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "VectorProcFrameLowering.h"
#include "VectorProcInstrInfo.h"
#include "VectorProcMachineFunctionInfo.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

void VectorProcFrameLowering::emitPrologue(MachineFunction &MF) const 
{
	MachineBasicBlock &MBB = MF.front();
	MachineFrameInfo *MFI = MF.getFrameInfo();
	const VectorProcInstrInfo &TII =
		*static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());
	MachineBasicBlock::iterator MBBI = MBB.begin();
	DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

	// Compute stack size. Allocate space, keeping SP 64 byte aligned so we
	// can do block vector load/stores
	int StackSize = (int) MFI->getStackSize();
	StackSize = (StackSize + 63) & ~63;	// Round up to 64 bytes
	assert(StackSize < 4096);	// XXX need to handle this.

	if (StackSize != 0)
	{
		BuildMI(MBB, MBBI, dl, TII.get(VectorProc::SUBISSI), VectorProc::SP_REG).addReg(VectorProc::SP_REG)
			.addImm(StackSize);
	}
	
	// XXX we are not generating cfi_def_cfa_offset or cfo_offset, which would be needed
	// for debug information.

    // Find the instruction past the last instruction that saves a callee-saved
    // register to the stack.  We need to set up FP after its old value has been
    // saved.
	const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();
	for (unsigned i = 0; i < CSI.size(); ++i)
		++MBBI;

	// fp = sp
	BuildMI(MBB, MBBI, dl, TII.get(VectorProc::MOVEREG)).addReg(VectorProc::FP_REG)
		.addReg(VectorProc::SP_REG);
}

void VectorProcFrameLowering::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
 	MachineBasicBlock::iterator I) const 
{
	MachineInstr &MI = *I;
	DebugLoc DL = MI.getDebugLoc();
	int Size = MI.getOperand(0).getImm();
	if (MI.getOpcode() == VectorProc::ADJCALLSTACKDOWN)
		Size = -Size;

	const VectorProcInstrInfo &TII =
		*static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());

	if (Size)
	{
		BuildMI(MBB, I, DL, TII.get(VectorProc::ADDISSI), VectorProc::SP_REG).addReg(VectorProc::SP_REG)
			.addImm(Size);
	}
	
	MBB.erase(I);
}

void VectorProcFrameLowering::emitEpilogue(MachineFunction &MF,
	MachineBasicBlock &MBB) const 
{
	MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
	MachineFrameInfo *MFI = MF.getFrameInfo();
	const VectorProcInstrInfo &TII =
		*static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());
	DebugLoc dl = MBBI->getDebugLoc();
	assert(MBBI->getOpcode() == VectorProc::RET &&
		 "Can only put epilog before 'retl' instruction!");

	uint64_t StackSize = MFI->getStackSize();

	StackSize = (StackSize + 63) & ~63;	// Round up to 64 bytes
	assert(StackSize < 16384);	// XXX need to handle this.

	if (StackSize != 0)
	{
		BuildMI(MBB, MBBI, dl, TII.get(VectorProc::ADDISSI), VectorProc::SP_REG).addReg(VectorProc::SP_REG)
			.addImm(StackSize);
	}
}

bool 
VectorProcFrameLowering::hasFP(const MachineFunction &MF) const 
{
	return true;	
}

bool 
VectorProcFrameLowering::spillCalleeSavedRegisters(MachineBasicBlock &MBB,
	MachineBasicBlock::iterator MI,
	const std::vector<CalleeSavedInfo> &CSI,
	const TargetRegisterInfo *TRI) const 
{
	MachineFunction *MF = MBB.getParent();
	MachineBasicBlock *EntryBlock = MF->begin();
	const TargetInstrInfo &TII = *MF->getTarget().getInstrInfo();

	for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
		// Add the callee-saved register as live-in. 
		// It's killed at the spill, unless the register is RA and return address
		// is taken.
		unsigned Reg = CSI[i].getReg();
		bool IsRAAndRetAddrIsTaken = Reg == VectorProc::LINK_REG
			&& MF->getFrameInfo()->isReturnAddressTaken();
		if (!IsRAAndRetAddrIsTaken)
			EntryBlock->addLiveIn(Reg);

		// Insert the spill to the stack frame.
		bool IsKill = !IsRAAndRetAddrIsTaken;
		const TargetRegisterClass *RC = TRI->getMinimalPhysRegClass(Reg);
		TII.storeRegToStackSlot(*EntryBlock, MI, Reg, IsKill,
			CSI[i].getFrameIdx(), RC, TRI);
	}

	return true;
}
