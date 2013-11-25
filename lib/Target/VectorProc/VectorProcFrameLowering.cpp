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
  MachineModuleInfo &MMI = MF.getMMI();
  const MCRegisterInfo *MRI = MMI.getContext().getRegisterInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();

  // Compute stack size. Allocate space, keeping SP 64 byte aligned so we
  // can do block vector load/stores
  int StackSize = (int) MFI->getStackSize();
  StackSize = (StackSize + 63) & ~63;	// Round up to 64 bytes
  assert(StackSize < 16384);	// XXX need to handle this.

  if (StackSize != 0)
  {
    BuildMI(MBB, MBBI, dl, TII.get(VectorProc::SUBISSI), VectorProc::SP_REG).addReg(VectorProc::SP_REG)
    .addImm(StackSize);
  }

  // emit ".cfi_def_cfa_offset StackSize" (debug information)
  MCSymbol *AdjustSPLabel = MMI.getContext().CreateTempSymbol();
  BuildMI(MBB, MBBI, dl,
          TII.get(TargetOpcode::PROLOG_LABEL)).addSym(AdjustSPLabel);
  MMI.addFrameInst(
    MCCFIInstruction::createDefCfaOffset(AdjustSPLabel, -StackSize));

  // Find the instruction past the last instruction that saves a callee-saved
  // register to the stack.  We need to set up FP after its old value has been
  // saved.
  const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();
  for (unsigned i = 0; i < CSI.size(); ++i)
    ++MBBI;

  // Iterate over list of callee-saved registers and emit .cfi_offset
  // directives (debug information)
  MCSymbol *CSLabel = MMI.getContext().CreateTempSymbol();
  BuildMI(MBB, MBBI, dl,
          TII.get(TargetOpcode::PROLOG_LABEL)).addSym(CSLabel);
  for (std::vector<CalleeSavedInfo>::const_iterator I = CSI.begin(),
       E = CSI.end(); I != E; ++I)
  {
    int64_t Offset = MFI->getObjectOffset(I->getFrameIdx());
    unsigned Reg = I->getReg();
    MMI.addFrameInst(MCCFIInstruction::createOffset(
                       CSLabel, MRI->getDwarfRegNum(Reg, 1), Offset));
  }

  // fp = sp
  BuildMI(MBB, MBBI, dl, TII.get(VectorProc::MOVESS)).addReg(VectorProc::FP_REG)
  .addReg(VectorProc::SP_REG);


  // emit ".cfi_def_cfa_register $fp" (debug information)
  MCSymbol *SetFPLabel = MMI.getContext().CreateTempSymbol();
  BuildMI(MBB, MBBI, dl,
          TII.get(TargetOpcode::PROLOG_LABEL)).addSym(SetFPLabel);
  MMI.addFrameInst(MCCFIInstruction::createDefCfaRegister(
                     SetFPLabel, MRI->getDwarfRegNum(VectorProc::FP_REG, true)));
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

bool
VectorProcFrameLowering::hasFP(const MachineFunction &MF) const
{
  return true;
}

void VectorProcFrameLowering::processFunctionBeforeCalleeSavedScan(MachineFunction &MF,
    RegScavenger *RS) const
{
  // Need to ensure the FP register is always saved.  The prologue code we
  // insert above will overwrite it, so mark it used here.
  MF.getRegInfo().setPhysRegUsed(VectorProc::FP_REG);
}
