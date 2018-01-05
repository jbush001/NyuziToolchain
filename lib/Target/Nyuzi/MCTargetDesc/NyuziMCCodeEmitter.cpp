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

  unsigned encodeBranchTargetOpValue20(const MCInst &MI, unsigned OpNo,
                                       SmallVectorImpl<MCFixup> &Fixups,
                                       const MCSubtargetInfo &STI) const;
  unsigned encodeBranchTargetOpValue25(const MCInst &MI, unsigned OpNo,
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
} // namespace

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
unsigned NyuziMCCodeEmitter::encodeBranchTargetOpValue20(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm();

  assert(MO.isExpr() &&
         "encodeBranchTargetOpValue expects only expressions or an immediate");

  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   MCFixupKind(Nyuzi::fixup_Nyuzi_Branch20),
                                   MI.getLoc()));
  return 0;
}

unsigned NyuziMCCodeEmitter::encodeBranchTargetOpValue25(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups,
    const MCSubtargetInfo &STI) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  if (MO.isImm())
    return MO.getImm();

  assert(MO.isExpr() &&
         "encodeBranchTargetOpValue expects only expressions or an immediate");

  Fixups.push_back(MCFixup::create(0, MO.getExpr(),
                                   MCFixupKind(Nyuzi::fixup_Nyuzi_Branch25),
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

  if (offsetOp.isImm())
      encoding |= static_cast<short>(offsetOp.getImm()) << 5;
  else if (const NyuziMCExpr *McExpr = dyn_cast<NyuziMCExpr>(offsetOp.getExpr())) {
    if (McExpr->getKind() == NyuziMCExpr::VK_Nyuzi_GOT) {
      Fixups.push_back(MCFixup::create(0, McExpr->getSubExpr(),
                       MCFixupKind(Nyuzi::fixup_Nyuzi_GOT),
                       MI.getLoc()));
    } else
      llvm_unreachable("Second operand of memory op is unknown type.");
  } else
    llvm_unreachable("Second operand of memory op is unknown type.");

  return encoding;
}

#include "NyuziGenMCCodeEmitter.inc"
