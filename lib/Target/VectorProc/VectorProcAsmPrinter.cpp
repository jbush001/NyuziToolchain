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
#include "VectorProc.h"
#include "VectorProcInstrInfo.h"
#include "VectorProcTargetMachine.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/Mangler.h"
using namespace llvm;

namespace {
  class VectorProcAsmPrinter : public AsmPrinter {
  public:
    explicit VectorProcAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
      : AsmPrinter(TM, Streamer) {}

    virtual const char *getPassName() const {
      return "VectorProc Assembly Printer";
    }

    void printOperand(const MachineInstr *MI, int opNum, raw_ostream &OS);
    void printMemOperand(const MachineInstr *MI, int opNum, raw_ostream &OS,
                         const char *Modifier = 0);
	void printComputeFrameAddr(const MachineInstr *MI, int opNum,
                                      raw_ostream &O);

    virtual void EmitInstruction(const MachineInstr *MI) {
      SmallString<128> Str;
      raw_svector_ostream OS(Str);
      printInstruction(MI, OS);
      OutStreamer.EmitRawText(OS.str());
    }
    void printInstruction(const MachineInstr *MI, raw_ostream &OS);// autogen'd.
    static const char *getRegisterName(unsigned RegNo);

    bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                         unsigned AsmVariant, const char *ExtraCode,
                         raw_ostream &O);
    bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNo,
                               unsigned AsmVariant, const char *ExtraCode,
                               raw_ostream &O);

    bool printGetPCX(const MachineInstr *MI, unsigned OpNo, raw_ostream &OS);
    
    virtual bool isBlockOnlyReachableByFallthrough(const MachineBasicBlock *MBB)
                       const;

    virtual MachineLocation getDebugValueLocation(const MachineInstr *MI) const;
    virtual void EmitFunctionBodyEnd();
  };
} // end of anonymous namespace

#include "VectorProcGenAsmWriter.inc"

void VectorProcAsmPrinter::printOperand(const MachineInstr *MI, int opNum,
                                   raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand (opNum);
  bool CloseParen = false;
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << StringRef(getRegisterName(MO.getReg())).lower();
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

			O << "(" << getRegisterName(MO.getReg()) << ")";
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

// In the case where we want to compute the offset of some stack object, this will
// print the expression.
void VectorProcAsmPrinter::printComputeFrameAddr(const MachineInstr *MI, int opNum,
                                      raw_ostream &O) 
{
	const MachineOperand &MO = MI->getOperand(opNum);
	switch (MO.getType())
	{
		case MachineOperand::MO_Register: {
			int operand = MI->getOperand(opNum+1).getImm();
			O << getRegisterName(MO.getReg()) << ", " << operand;
			break;
		}
		
		default:
			errs() << "What is " << MO.getType();
		    llvm_unreachable("<unknown operand type>");
	}
}
/// PrintAsmOperand - Print out an operand for an inline asm expression.
///
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
EmitFunctionBodyEnd()
{
	OutStreamer.EmitDataRegion(MCDR_DataRegionEnd);
}

// Force static initialization.
extern "C" void LLVMInitializeVectorProcAsmPrinter() { 
  RegisterAsmPrinter<VectorProcAsmPrinter> X(TheVectorProcTarget);
}
