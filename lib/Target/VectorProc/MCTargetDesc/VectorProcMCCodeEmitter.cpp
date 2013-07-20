//===-- VectorProcMCCodeEmitter.cpp - Convert VectorProc code to machine code ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VectorProcMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "mccodeemitter"
#include "MCTargetDesc/VectorProcFixupKinds.h"
#include "MCTargetDesc/VectorProcMCTargetDesc.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
using namespace llvm;

STATISTIC(MCNumEmitted, "Number of MC instructions emitted");

namespace {
class VectorProcMCCodeEmitter : public MCCodeEmitter {
  VectorProcMCCodeEmitter(const VectorProcMCCodeEmitter &); // DO NOT IMPLEMENT
  void operator=(const VectorProcMCCodeEmitter &); // DO NOT IMPLEMENT
  const MCInstrInfo &MCII;
  const MCSubtargetInfo &STI;
  MCContext &Ctx;

public:
  VectorProcMCCodeEmitter(const MCInstrInfo &mcii, const MCSubtargetInfo &sti,
                    MCContext &ctx)
    : MCII(mcii), STI(sti), Ctx(ctx) {
    }

  ~VectorProcMCCodeEmitter() {}

  // getBinaryCodeForInstr - TableGen'erated function for getting the
  // binary encoding for an instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups) const;

   // getMachineOpValue - Return binary encoding of operand. If the machin
   // operand requires relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &MI,const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups) const;

  unsigned getMemoryOpValue(const MCInst &MI, unsigned Op,
                            SmallVectorImpl<MCFixup> &Fixups) const;

  unsigned getJumpTargetOpValue(const MCInst &MI, unsigned OpNo,
                     SmallVectorImpl<MCFixup> &Fixups) const;

  // Emit one byte through output stream (from MCBlazeMCCodeEmitter)
  void EmitByte(unsigned char C, unsigned &CurByte, raw_ostream &OS) const {
    OS << (char)C;
    ++CurByte;
  }

  // Emit a series of bytes (little endian) (from MCBlazeMCCodeEmitter)
  void EmitLEConstant(uint64_t Val, unsigned Size, unsigned &CurByte,
                    raw_ostream &OS) const {
    assert(Size <= 8 && "size too big in emit constant");

    for (unsigned i = 0; i != Size; ++i) {
      EmitByte(Val & 255, CurByte, OS);
      Val >>= 8;
    }
  }


  void EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups) const;
};
} // end anonymous namepsace

MCCodeEmitter *llvm::createVectorProcMCCodeEmitter(const MCInstrInfo &MCII,
                                             const MCRegisterInfo &MRI,
                                             const MCSubtargetInfo &STI,
                                             MCContext &Ctx) {

  return new VectorProcMCCodeEmitter(MCII, STI, Ctx);
}

/// getMachineOpValue - Return binary encoding of operand. If the machine
/// operand requires relocation, record the relocation and return zero.
unsigned VectorProcMCCodeEmitter::
getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                  SmallVectorImpl<MCFixup> &Fixups) const {

  if (MO.isReg())
    return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());

  if (MO.isImm())
    return static_cast<unsigned>(MO.getImm());
  
  // MO must be an expression
  assert(MO.isExpr());

  const MCExpr *Expr = MO.getExpr();
  MCExpr::ExprKind Kind = Expr->getKind();

  if (Kind == MCExpr::Binary) {
    Expr = static_cast<const MCBinaryExpr*>(Expr)->getLHS();
    Kind = Expr->getKind();
  }

  assert (Kind == MCExpr::SymbolRef);

  VectorProc::Fixups FixupKind = VectorProc::Fixups(0);

  switch(cast<MCSymbolRefExpr>(Expr)->getKind()) {
    default: llvm_unreachable("Unknown fixup kind!");

    case MCSymbolRefExpr::VK_VectorProc_Abs32:
      FixupKind = VectorProc::fixup_VectorProc_Abs32;
      break;

    case MCSymbolRefExpr::VK_VectorProc_PCRel_MemAccExt:
      FixupKind = VectorProc::fixup_VectorProc_PCRel_MemAccExt;
      break;

    case MCSymbolRefExpr::VK_VectorProc_PCRel_MemAcc:
      FixupKind = VectorProc::fixup_VectorProc_PCRel_MemAcc;
      break;

    case MCSymbolRefExpr::VK_VectorProc_PCRel_Branch:
      FixupKind = VectorProc::fixup_VectorProc_PCRel_Branch;
      break;
  }

  // Push fixup (all info is contained within)
  Fixups.push_back(MCFixup::Create(0, MO.getExpr(), MCFixupKind(FixupKind)));

  return 0;
}

/// getJumpTargetOpValue - Return binary encoding of the jump
/// target operand. If the machine operand requires relocation,
/// record the relocation and return zero.
unsigned VectorProcMCCodeEmitter::
getJumpTargetOpValue(const MCInst &MI, unsigned OpNo,
                     SmallVectorImpl<MCFixup> &Fixups) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm()) return MO.getImm();

  assert(MO.isExpr() &&
         "getJumpTargetOpValue expects only expressions or an immediate");

  const MCExpr *Expr = MO.getExpr();
  Fixups.push_back(MCFixup::Create(0, Expr,
  	MCFixupKind(VectorProc::fixup_VectorProc_PCRel_Branch)));
  return 0;
}


void VectorProcMCCodeEmitter::
EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups) const {
  unsigned Opcode = MI.getOpcode();
  // Keep track of the current byte being emitted
  unsigned CurByte = 0;

  // Get instruction encoding and emit it
  ++MCNumEmitted;       // Keep track of the number of emitted insns.
  unsigned Value = getBinaryCodeForInstr(MI, Fixups);
  EmitLEConstant(Value, 4, CurByte, OS);
}

// Encode VectorProc Memory Operand.  The result is a packed field with the register
// in the low 5 bits and the offset in the remainder.  The instruction patterns
// will put these into the proper part of the instruction (VectorProcInstrFormats.td).
unsigned VectorProcMCCodeEmitter::
getMemoryOpValue(const MCInst &MI, unsigned Op,
	SmallVectorImpl<MCFixup> &Fixups) const {
	unsigned encoding;

	// Register
	const MCOperand op1 = MI.getOperand(1);
	// This is register/offset.  No need for relocation.
	assert(op1.isReg() && "First operand is not register.");
	encoding = Ctx.getRegisterInfo()->getEncodingValue(op1.getReg());

	// Offset
	MCOperand op2 = MI.getOperand(2);
	if (op2.isExpr())
	{
		// Load with a label. This is a PC relative load.  Add a fixup.
		// XXX Note that this assumes unmasked instructions.  A masked
		// instruction will not work and should nto be used.
		Fixups.push_back(MCFixup::Create(0, op2.getExpr(),
			 MCFixupKind(VectorProc::fixup_VectorProc_PCRel_MemAccExt)));
	}
	else if (op2.isImm())
		encoding |= static_cast<short>(op2.getImm()) << 5;
	else
		assert(op2.isImm() && "Second operand of memory op is unknown type.");
	
	return encoding;
}

#include "VectorProcGenMCCodeEmitter.inc"
