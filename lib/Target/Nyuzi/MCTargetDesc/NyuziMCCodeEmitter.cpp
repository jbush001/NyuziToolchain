//===-- NyuziMCCodeEmitter.cpp - Convert Nyuzi code to machine code  -----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the NyuziMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "mccodeemitter"

#include "MCTargetDesc/NyuziFixupKinds.h"
#include "MCTargetDesc/NyuziMCExpr.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

STATISTIC(MCNumEmitted, "Number of MC instructions emitted");

namespace {
class NyuziMCCodeEmitter : public MCCodeEmitter {
public:
  NyuziMCCodeEmitter(const MCInstrInfo &mcii, MCContext &ctx) : Ctx(ctx) {}

  // getBinaryCodeForInstr - TableGen'erated function for getting the
  // binary encoding for an instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const;

  // getMachineOpValue - Return binary encoding of operand. If the machine
  // operand requires relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &STI) const;

  unsigned encodeMemoryOpValue(const MCInst &MI, unsigned Op,
                               SmallVectorImpl<MCFixup> &Fixups,
                               const MCSubtargetInfo &STI) const;

  unsigned encodeLEAValue(const MCInst &MI, unsigned Op,
                          SmallVectorImpl<MCFixup> &Fixups,
                          const MCSubtargetInfo &STI) const;

  unsigned encodeBranchTargetOpValue(const MCInst &MI, unsigned OpNo,
                                     SmallVectorImpl<MCFixup> &Fixups,
                                     const MCSubtargetInfo &STI) const;

  unsigned encodeJumpTableAddr(const MCInst &MI, unsigned OpNo,
                               SmallVectorImpl<MCFixup> &Fixups,
                               const MCSubtargetInfo &STI) const;

  // Emit one byte through output stream (from MCBlazeMCCodeEmitter)
  void EmitByte(unsigned char C, raw_ostream &OS) const { OS << (char)C; }

  void EmitLEConstant(uint64_t Val, unsigned Size, raw_ostream &OS) const {
    assert(Size <= 8 && "size too big in emit constant");

    for (unsigned i = 0; i != Size; ++i) {
      EmitByte(Val & 255, OS);
      Val >>= 8;
    }
  }

  void encodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override;

private:
  NyuziMCCodeEmitter(const NyuziMCCodeEmitter &) = delete;
  void operator=(const NyuziMCCodeEmitter &) = delete;
  MCContext &Ctx;
};
} // end anonymous namepsace

MCCodeEmitter *llvm::createNyuziMCCodeEmitter(const MCInstrInfo &MCII,
                                              const MCRegisterInfo &MRI,
                                              MCContext &Ctx) {

  return new NyuziMCCodeEmitter(MCII, Ctx);
}

/// getMachineOpValue - Return binary encoding of operand.
unsigned
NyuziMCCodeEmitter::getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                                      SmallVectorImpl<MCFixup> &Fixups,
                                      const MCSubtargetInfo &STI) const {

  if (MO.isReg())
    return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());

  if (MO.isImm())
    return static_cast<unsigned>(MO.getImm());

  assert(MO.isExpr());
  const MCExpr *Expr = MO.getExpr();
  if (const NyuziMCExpr *McExpr = dyn_cast<NyuziMCExpr>(Expr)) {
    switch (McExpr->getKind()) {
    case NyuziMCExpr::VK_Nyuzi_ABS_HI:
      Fixups.push_back(MCFixup::create(0, MO.getExpr(), MCFixupKind(
                       Nyuzi::fixup_Nyuzi_HI19)));
      break;

    case NyuziMCExpr::VK_Nyuzi_ABS_LO:
      Fixups.push_back(MCFixup::create(0, MO.getExpr(), MCFixupKind(
                       Nyuzi::fixup_Nyuzi_IMM_LO13)));
      break;

    default:
      llvm_unreachable("Unknown fixup type");
    }
  }

  return 0;
}

// encodeBranchTargetOpValue - Return binary encoding of the jump
// target operand. If the machine operand requires relocation,
// record the relocation and return zero.
unsigned NyuziMCCodeEmitter::encodeBranchTargetOpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm();

  assert(MO.isExpr() &&
         "encodeBranchTargetOpValue expects only expressions or an immediate");

  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   MCFixupKind(Nyuzi::fixup_Nyuzi_PCRel_Branch),
                                   MI.getLoc()));
  return 0;
}

void NyuziMCCodeEmitter::encodeInstruction(const MCInst &MI, raw_ostream &OS,
                                           SmallVectorImpl<MCFixup> &Fixups,
                                           const MCSubtargetInfo &STI) const {
  // Get instruction encoding and emit it
  ++MCNumEmitted; // Keep track of the number of emitted insns.
  unsigned Value = getBinaryCodeForInstr(MI, Fixups, STI);
  EmitLEConstant(Value, 4, OS);
}

unsigned
NyuziMCCodeEmitter::encodeJumpTableAddr(const MCInst &MI, unsigned Op,
                                        SmallVectorImpl<MCFixup> &Fixups,
                                        const MCSubtargetInfo &STI) const {
  MCOperand label = MI.getOperand(2);
  Fixups.push_back(MCFixup::create(
      0, label.getExpr(),
      MCFixupKind(Nyuzi::fixup_Nyuzi_PCRel_ComputeLabelAddress), MI.getLoc()));
  return 0;
}

unsigned NyuziMCCodeEmitter::encodeLEAValue(const MCInst &MI, unsigned Op,
                                            SmallVectorImpl<MCFixup> &Fixups,
                                            const MCSubtargetInfo &STI) const {

  MCOperand baseReg = MI.getOperand(1);
  MCOperand offsetOp = MI.getOperand(2);

  assert(baseReg.isReg() && "First operand of LEA op is not register.");
  unsigned encoding = Ctx.getRegisterInfo()->getEncodingValue(baseReg.getReg());

  if (offsetOp.isExpr()) {
    // Load with a label. This is a PC relative load.  Add a fixup.
    Fixups.push_back(MCFixup::create(
        0, offsetOp.getExpr(),
        MCFixupKind(Nyuzi::fixup_Nyuzi_PCRel_ComputeLabelAddress),
        MI.getLoc()));
  } else if (offsetOp.isImm())
    encoding |= static_cast<short>(offsetOp.getImm()) << 5;
  else
    assert(offsetOp.isImm() && "Second operand of LEA op is unknown type.");

  return encoding;
}

// Encode Nyuzi Memory Operand.  The result is a packed field with the
// register in the low 5 bits and the offset in the remainder.  The instruction
// patterns will put these into the proper part of the instruction
// (NyuziInstrFormats.td).
unsigned
NyuziMCCodeEmitter::encodeMemoryOpValue(const MCInst &MI, unsigned Op,
                                        SmallVectorImpl<MCFixup> &Fixups,
                                        const MCSubtargetInfo &STI) const {
  unsigned encoding;

  MCOperand baseReg;
  MCOperand offsetOp;

  if (MI.getOpcode() == Nyuzi::STORE_SYNC) {
    // Store sync has an additional machine operand for the success value
    baseReg = MI.getOperand(2);
    offsetOp = MI.getOperand(3);
  } else {
    baseReg = MI.getOperand(1);
    offsetOp = MI.getOperand(2);
  }

  // Register
  // This is register/offset.
  assert(baseReg.isReg() && "First operand is not register.");
  encoding = Ctx.getRegisterInfo()->getEncodingValue(baseReg.getReg());

  // Offset
  if (offsetOp.isExpr()) {
    // Load with a label. This is a PC relative load.  Add a fixup.
    // XXX Note that this assumes unmasked instructions.  A masked
    // instruction will not work and should not be used. Check for this
    // and return an error.
    Fixups.push_back(MCFixup::create(
        0, offsetOp.getExpr(), MCFixupKind(Nyuzi::fixup_Nyuzi_PCRel_MemAccExt),
        MI.getLoc()));
  } else if (offsetOp.isImm())
    encoding |= static_cast<short>(offsetOp.getImm()) << 5;
  else
    assert(offsetOp.isImm() && "Second operand of memory op is unknown type.");

  return encoding;
}

#include "NyuziGenMCCodeEmitter.inc"
