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

void VectorProcFrameLowering::emitPrologue(MachineFunction &MF) const {
  MachineBasicBlock &MBB = MF.front();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const VectorProcInstrInfo &TII =
    *static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Get the number of bytes to allocate from the FrameInfo
  int StackSize = (int) MFI->getStackSize();
  StackSize = (StackSize + 63) & ~63;	// Round up to 64 bytes
  assert(StackSize < 4096);	// XXX need to handle this.

  if (StackSize != 0)
  {
    BuildMI(MBB, MBBI, dl, TII.get(SP::SUBISI), SP::S29).addReg(SP::S29)
      .addImm(StackSize);
  }
}

void VectorProcFrameLowering::
eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator I) const {

// XXX hack: hasReservedCallFrame isn't doing quite what I expect.  Need to understand
// this.
//  if (!hasReservedCallFrame(MF)) {
    MachineInstr &MI = *I;
    DebugLoc DL = MI.getDebugLoc();
    int Size = MI.getOperand(0).getImm();
    if (MI.getOpcode() == SP::ADJCALLSTACKDOWN)
      Size = -Size;
    const VectorProcInstrInfo &TII =
      *static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());
    if (Size)
    {
      BuildMI(MBB, I, DL, TII.get(SP::ADDISI), SP::S29).addReg(SP::S29)
        .addImm(Size);
	}
//  }
  MBB.erase(I);
}


void VectorProcFrameLowering::emitEpilogue(MachineFunction &MF,
                                  MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const VectorProcInstrInfo &TII =
    *static_cast<const VectorProcInstrInfo*>(MF.getTarget().getInstrInfo());
  DebugLoc dl = MBBI->getDebugLoc();
  assert(MBBI->getOpcode() == SP::RET &&
         "Can only put epilog before 'retl' instruction!");

  uint64_t StackSize = MFI->getStackSize();

  StackSize = (StackSize + 63) & ~63;	// Round up to 64 bytes
  assert(StackSize < 4096);	// XXX need to handle this.

  if (StackSize != 0)
  {
    BuildMI(MBB, MBBI, dl, TII.get(SP::ADDISI), SP::S29).addReg(SP::S29)
      .addImm(StackSize);
  }


}

bool VectorProcFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  return MF.getTarget().Options.DisableFramePointerElim(MF) ||
      MFI->hasVarSizedObjects() || MFI->isFrameAddressTaken();
}

bool VectorProcFrameLowering::
spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                          MachineBasicBlock::iterator MI,
                          const std::vector<CalleeSavedInfo> &CSI,
                          const TargetRegisterInfo *TRI) const {

  MachineFunction *MF = MBB.getParent();
  MachineBasicBlock *EntryBlock = MF->begin();
  const TargetInstrInfo &TII = *MF->getTarget().getInstrInfo();

  for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
    // Add the callee-saved register as live-in. 
    // It's killed at the spill, unless the register is RA and return address
    // is taken.
    unsigned Reg = CSI[i].getReg();
    bool IsRAAndRetAddrIsTaken = Reg == SP::S31
        && MF->getFrameInfo()->isReturnAddressTaken();
    if (!IsRAAndRetAddrIsTaken)
      EntryBlock->addLiveIn(Reg);

    EntryBlock->addLiveIn(Reg);

    // Insert the spill to the stack frame.
    bool IsKill = !IsRAAndRetAddrIsTaken;
    const TargetRegisterClass *RC = TRI->getMinimalPhysRegClass(Reg);
    TII.storeRegToStackSlot(*EntryBlock, MI, Reg, IsKill,
                            CSI[i].getFrameIdx(), RC, TRI);
  }

  return true;
}
