//===-- VectorProcAsmPrinter.cpp - VectorProc LLVM assembly writer ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to GAS-format VECTORPROC assembly language.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "InstPrinter/VectorProcInstPrinter.h"
#include "VectorProcAsmPrinter.h"
#include "VectorProc.h"
#include "VectorProcInstrInfo.h"
#include "VectorProcTargetMachine.h"
#include "VectorProcMCInstLower.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
#include "llvm/Target/Mangler.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
using namespace llvm;

void VectorProcAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  MachineBasicBlock::const_instr_iterator I = MI;
  MachineBasicBlock::const_instr_iterator E = MI->getParent()->instr_end();

  do {
	MCInst TmpInst;
	MCInstLowering.Lower(MI, TmpInst);

	OutStreamer.EmitInstruction(TmpInst);
  } while ((I != E) && I->isInsideBundle());
}


void VectorProcAsmPrinter::printOperand(const MachineInstr *MI, int opNum,
                                   raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand (opNum);
  bool CloseParen = false;
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << StringRef(VectorProcInstPrinter::getRegisterName(MO.getReg())).lower();
    break;

  case MachineOperand::MO_Immediate:
    O << (int)MO.getImm();
    break;
  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    return;
  case MachineOperand::MO_GlobalAddress:
    O << *Mang->getSymbol(MO.getGlobal());
    break;
  case MachineOperand::MO_ExternalSymbol:
    O << MO.getSymbolName();
    break;
  case MachineOperand::MO_ConstantPoolIndex:
    O << MAI->getPrivateGlobalPrefix() << "CPI" << getFunctionNumber() << "_"
      << MO.getIndex();
    break;
  default:
    llvm_unreachable("<unknown operand type>");
  }
  if (CloseParen) O << ")";
}

// Body of address.  eg: mem_l[THIS]
void VectorProcAsmPrinter::printMemOperand(const MachineInstr *MI, int opNum,
                                      raw_ostream &O, const char *Modifier) 
{
	const MachineOperand &MO = MI->getOperand(opNum);
	switch (MO.getType())
	{
		case MachineOperand::MO_Register:
			if (MI->getOperand(opNum+1).isImm())
			{
				int operand = MI->getOperand(opNum+1).getImm();
				if (operand != 0)
					O << operand;
			}

			O << "(" << VectorProcInstPrinter::getRegisterName(MO.getReg()) << ")";
			break;

		case MachineOperand::MO_GlobalAddress:
			O << *Mang->getSymbol(MO.getGlobal());
			break;
			
		case MachineOperand::MO_ConstantPoolIndex:
			O << MAI->getPrivateGlobalPrefix() << "CPI" << getFunctionNumber() << "_"
				<< MO.getIndex();
			break;
		
		default:
			errs() << "What is " << MO.getType();
		    llvm_unreachable("<unknown operand type>");
	}
}

/// PrintAsmOperand - Print out an operand for an inline asm expression.
bool VectorProcAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                      unsigned AsmVariant,
                                      const char *ExtraCode,
                                      raw_ostream &O) {
  if (ExtraCode && ExtraCode[0]) {
    if (ExtraCode[1] != 0) return true; // Unknown modifier.

    switch (ExtraCode[0]) {
		default:
		  // See if this is a generic print operand
		  return AsmPrinter::PrintAsmOperand(MI, OpNo, AsmVariant, ExtraCode, O);
		case 'r':
		 break;
    }
  }

  printOperand(MI, OpNo, O);

  return false;
}

bool VectorProcAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                            unsigned OpNo, unsigned AsmVariant,
                                            const char *ExtraCode,
                                            raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return true;  // Unknown modifier

  printMemOperand(MI, OpNo, O);

  return false;
}

/// isBlockOnlyReachableByFallthough - Return true if the basic block has
/// exactly one predecessor and the control transfer mechanism between
/// the predecessor and this block is a fall-through.
///
/// This overrides AsmPrinter's implementation to handle delay slots.
bool VectorProcAsmPrinter::
isBlockOnlyReachableByFallthrough(const MachineBasicBlock *MBB) const {
  // If this is a landing pad, it isn't a fall through.  If it has no preds,
  // then nothing falls through to it.
  if (MBB->isLandingPad() || MBB->pred_empty())
    return false;
  
  // If there isn't exactly one predecessor, it can't be a fall through.
  MachineBasicBlock::const_pred_iterator PI = MBB->pred_begin(), PI2 = PI;
  ++PI2;
  if (PI2 != MBB->pred_end())
    return false;
  
  // The predecessor has to be immediately before this block.
  const MachineBasicBlock *Pred = *PI;
  
  if (!Pred->isLayoutSuccessor(MBB))
    return false;
  
  // Check if the last terminator is an unconditional branch.
  MachineBasicBlock::const_iterator I = Pred->end();
  while (I != Pred->begin() && !(--I)->isTerminator())
    ; // Noop
  return I == Pred->end() || !I->isBarrier();
}

MachineLocation VectorProcAsmPrinter::
getDebugValueLocation(const MachineInstr *MI) const {
  assert(MI->getNumOperands() == 4 && "Invalid number of operands!");
  assert(MI->getOperand(0).isReg() && MI->getOperand(1).isImm() &&
         "Unexpected MachineOperand types");
  return MachineLocation(MI->getOperand(0).getReg(),
                         MI->getOperand(1).getImm());
}

void VectorProcAsmPrinter::
EmitFunctionBodyStart() {
  MCInstLowering.Initialize(Mang, &MF->getContext());
}

void VectorProcAsmPrinter::
EmitFunctionBodyEnd()
{
	OutStreamer.EmitDataRegion(MCDR_DataRegionEnd);
}

void VectorProcAsmPrinter::
EmitConstantPool() 
{
  const MachineConstantPool *MCP = MF->getConstantPool();
  const std::vector<MachineConstantPoolEntry> &CP = MCP->getConstants();
  if (CP.empty()) return;

  // Emit constants for this function in the same section as the function so 
  // they are close by and can be accessed with PC relative addresses.
  const Function *F = MF->getFunction();
  OutStreamer.SwitchSection(getObjFileLowering().SectionForGlobal(F, Mang, TM));
  unsigned Offset = 0;
  for (unsigned i = 0, e = CP.size(); i != e; ++i) {
    const MachineConstantPoolEntry &CPE = CP[i];
    unsigned Align = CPE.getAlignment();
    EmitAlignment(Log2_32(CPE.getAlignment()));
    OutStreamer.EmitLabel(GetCPISymbol(i));
    if (CPE.isMachineConstantPoolEntry())
      EmitMachineConstantPoolValue(CPE.Val.MachineCPVal);
    else
      EmitGlobalConstant(CPE.Val.ConstVal);
  }
}

// Force static initialization.
extern "C" void LLVMInitializeVectorProcAsmPrinter() { 
  RegisterAsmPrinter<VectorProcAsmPrinter> X(TheVectorProcTarget);
}
