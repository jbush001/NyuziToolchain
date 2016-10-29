//===-- NyuziAsmPrinter.cpp - Nyuzi LLVM assembly writer -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "nyuzi-asm-printer"

#include "NyuziAsmPrinter.h"
#include "InstPrinter/NyuziInstPrinter.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "Nyuzi.h"
#include "NyuziInstrInfo.h"
#include "NyuziMCInstLower.h"
#include "NyuziTargetMachine.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetLoweringObjectFile.h"

using namespace llvm;

void NyuziAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  MachineBasicBlock::const_instr_iterator I = MI->getIterator();
  MachineBasicBlock::const_instr_iterator E = MI->getParent()->instr_end();

  do {
    MCInst TmpInst;
    MCInstLowering.Lower(MI, TmpInst);
    EmitToStreamer(*OutStreamer, TmpInst);
    if (MI->getOpcode() == Nyuzi::JUMP_TABLE)
      EmitInlineJumpTable(MI);
  } while ((++I != E) && I->isInsideBundle());
}

void NyuziAsmPrinter::EmitFunctionBodyStart() {
  MCInstLowering.Initialize(&MF->getContext());
}

void NyuziAsmPrinter::EmitConstantPool() {
  const MachineConstantPool *MCP = MF->getConstantPool();
  const std::vector<MachineConstantPoolEntry> &CP = MCP->getConstants();
  if (CP.empty())
    return;

  // Emit constants for this function in the same section as the function so
  // they are close by and can be accessed with PC relative addresses.
  const Function *F = MF->getFunction();
  OutStreamer->SwitchSection(
      getObjFileLowering().SectionForGlobal(F, TM));
  OutStreamer->EmitDataRegion(MCDR_DataRegion);
  for (unsigned i = 0, e = CP.size(); i != e; ++i) {
    const MachineConstantPoolEntry &CPE = CP[i];
    EmitAlignment(Log2_32(CPE.getAlignment()));
    OutStreamer->EmitLabel(GetCPISymbol(i));
    if (CPE.isMachineConstantPoolEntry())
      EmitMachineConstantPoolValue(CPE.Val.MachineCPVal);
    else
      EmitGlobalConstant(MF->getDataLayout(), CPE.Val.ConstVal);
  }

  OutStreamer->EmitDataRegion(MCDR_DataRegionEnd);
}

// Print operand for inline assembly
bool NyuziAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                      unsigned AsmVariant,
                                      const char *ExtraCode, raw_ostream &O) {

  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, AsmVariant, ExtraCode, O);

  const MachineOperand &MO = MI->getOperand(OpNo);
  if (MO.getType() == MachineOperand::MO_Register) {
    O << NyuziInstPrinter::getRegisterName(MO.getReg());
    return false;
  } else if (MO.getType() == MachineOperand::MO_Immediate) {
    O << MO.getImm();
    return false;
  }

  return true;
}

bool NyuziAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                            unsigned OpNum, unsigned AsmVariant,
                                            const char *ExtraCode,
                                            raw_ostream &O) {

  const MachineOperand &MO = MI->getOperand(OpNum);
  assert(MO.isReg() && "unexpected inline asm memory operand");
  O << "(" << NyuziInstPrinter::getRegisterName(MO.getReg()) << ")";

  return false;
}

MCSymbol *NyuziAsmPrinter::GetJumpTableLabel(unsigned uid) const {
  SmallString<60> Name;
  raw_svector_ostream(Name) << MAI->getPrivateGlobalPrefix() << "JTI"
                            << getFunctionNumber() << '_' << uid;
  return OutContext.getOrCreateSymbol(Name.str());
}

void NyuziAsmPrinter::EmitInlineJumpTable(const MachineInstr *MI) {
  const MachineOperand &MO1 = MI->getOperand(1);
  unsigned JTI = MO1.getIndex();
  MCSymbol *JTISymbol = GetJumpTableLabel(JTI);
  OutStreamer->EmitLabel(JTISymbol);
  const MachineJumpTableInfo *MJTI = MF->getJumpTableInfo();
  const std::vector<MachineJumpTableEntry> &JT = MJTI->getJumpTables();
  const std::vector<MachineBasicBlock *> &JTBBs = JT[JTI].MBBs;
  OutStreamer->EmitDataRegion(MCDR_DataRegionJT32);
  for (const auto &MBB : JTBBs) {
    const MCExpr *Expr = MCSymbolRefExpr::create(MBB->getSymbol(), OutContext);
    OutStreamer->EmitValue(Expr, 4);
  }

  OutStreamer->EmitDataRegion(MCDR_DataRegionEnd);
}

// Force static initialization.
extern "C" void LLVMInitializeNyuziAsmPrinter() {
  RegisterAsmPrinter<NyuziAsmPrinter> X(TheNyuziTarget);
}
