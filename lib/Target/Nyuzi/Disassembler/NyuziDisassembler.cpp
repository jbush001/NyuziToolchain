//===- NyuziDisassembler.cpp - Disassembler for Nyuzi ---------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is part of the Nyuzi Disassembler.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "nyuzi-disassembler"

#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "Nyuzi.h"
#include "NyuziRegisterInfo.h"
#include "NyuziSubtarget.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace llvm {

class NyuziDisassembler : public MCDisassembler {
public:
  NyuziDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx,
                    const MCRegisterInfo *Info)
      : MCDisassembler(STI, Ctx), RegInfo(Info) {}

  ~NyuziDisassembler() override = default;

  const MCRegisterInfo *getRegInfo() const { return RegInfo; }

  /// getInstruction - See MCDisassembler.
  DecodeStatus getInstruction(MCInst &instr, uint64_t &size,
                              ArrayRef<uint8_t> Bytes, uint64_t address,
                              raw_ostream &vStream,
                              raw_ostream &cStream) const override;

private:
  const MCRegisterInfo *RegInfo;
};

} // namespace llvm

static DecodeStatus decodeSimm9Value(MCInst &Inst, unsigned Insn,
                                     uint64_t Address, const void *Decoder);

static DecodeStatus decodeSimm14Value(MCInst &Inst, unsigned Insn,
                                      uint64_t Address, const void *Decoder);

static DecodeStatus decodeSimm19Value(MCInst &Inst, unsigned Insn,
                                      uint64_t Address, const void *Decoder);

static DecodeStatus decodeScalarMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder);

static DecodeStatus decodeVectorMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder);

static DecodeStatus decodeBranchTargetOpValue20(MCInst &Inst, unsigned Offset,
                                                uint64_t Address,
                                                const void *Decoder);

static DecodeStatus decodeBranchTargetOpValue25(MCInst &Inst, unsigned Offset,
                                                uint64_t Address,
                                                const void *Decoder);

DecodeStatus DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo,
                                      uint64_t Address, const void *Decoder);

DecodeStatus DecodeVR512RegisterClass(MCInst &Inst, unsigned RegNo,
                                      uint64_t Address, const void *Decoder);

namespace llvm {
extern Target TheNyuziTarget;
}

static MCDisassembler *createNyuziDisassembler(const Target &T,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx) {
  return new NyuziDisassembler(STI, Ctx, T.createMCRegInfo(""));
}

extern "C" void LLVMInitializeNyuziDisassembler() {
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(TheNyuziTarget,
                                         createNyuziDisassembler);
}

#include "NyuziGenDisassemblerTables.inc"

/// readInstruction - read 32 bit word in machine endianess.
static DecodeStatus readInstruction32(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint32_t &Insn) {
  // We want to read exactly 4 Bytes of data.
  if (Bytes.size() < 4) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Insn =
      (Bytes[0] << 0) | (Bytes[1] << 8) | (Bytes[2] << 16) | (Bytes[3] << 24);

  return MCDisassembler::Success;
}

DecodeStatus NyuziDisassembler::getInstruction(MCInst &instr, uint64_t &Size,
                                               ArrayRef<uint8_t> Bytes,
                                               uint64_t Address,
                                               raw_ostream &vStream,
                                               raw_ostream &cStream) const {
  uint32_t Insn;

  DecodeStatus Result = readInstruction32(Bytes, Address, Size, Insn);
  if (Result == MCDisassembler::Fail)
    return MCDisassembler::Fail;

  // Calling the auto-generated decoder function.
  Result = decodeInstruction(DecoderTable32, instr, Insn, Address, this, STI);
  if (Result != MCDisassembler::Fail) {
    Size = 4;
    return Result;
  }

  return MCDisassembler::Fail;
}

static unsigned getReg(const void *D, unsigned RC, unsigned RegNo) {
  const NyuziDisassembler *Dis = static_cast<const NyuziDisassembler *>(D);
  return *(Dis->getRegInfo()->getRegClass(RC).begin() + RegNo);
}

static DecodeStatus decodeMemoryOpValue(MCInst &Inst, unsigned Insn,
                                        uint64_t Address, const void *Decoder,
                                        unsigned RC) {
  // XXX this depends on the instruction type (has mask or not)
  int Offset = SignExtend32<15>(fieldFromInstruction(Insn, 5, 15));
  int RegisterIndex = fieldFromInstruction(Insn, 0, 5);
  unsigned BaseReg = getReg(Decoder, RC, RegisterIndex);

  Inst.addOperand(MCOperand::createReg(BaseReg));
  Inst.addOperand(MCOperand::createImm(Offset));

  return MCDisassembler::Success;
}

static DecodeStatus decodeScalarMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder) {
  return decodeMemoryOpValue(Inst, Insn, Address, Decoder,
                             Nyuzi::GPR32RegClassID);
}

static DecodeStatus decodeSimm9Value(MCInst &Inst, unsigned Insn,
                                     uint64_t Address, const void *Decoder) {

  Inst.addOperand(MCOperand::createImm(SignExtend32<9>(Insn)));
  return MCDisassembler::Success;
}

static DecodeStatus decodeSimm14Value(MCInst &Inst, unsigned Insn,
                                      uint64_t Address, const void *Decoder) {
  Inst.addOperand(MCOperand::createImm(SignExtend32<14>(Insn)));
  return MCDisassembler::Success;
}

static DecodeStatus decodeSimm19Value(MCInst &Inst, unsigned Insn,
                                      uint64_t Address, const void *Decoder) {
  Inst.addOperand(MCOperand::createImm(Insn));
  return MCDisassembler::Success;
}

static DecodeStatus decodeVectorMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder) {
  return decodeMemoryOpValue(Inst, Insn, Address, Decoder,
                             Nyuzi::VR512RegClassID);
}

static DecodeStatus decodeBranchTargetOpValue20(MCInst &Inst, unsigned Offset,
                                                uint64_t Address,
                                                const void *Decoder) {

  const MCDisassembler *Dis = static_cast<const MCDisassembler *>(Decoder);
  int32_t AdjustedOffset = SignExtend32<20>(Offset) * 4;
  if (!Dis->tryAddingSymbolicOperand(Inst, Address + AdjustedOffset,
                                     Address, true, 0, 20)) {
    Inst.addOperand(MCOperand::createImm(AdjustedOffset));
  }

  return MCDisassembler::Success;
}

static DecodeStatus decodeBranchTargetOpValue25(MCInst &Inst, unsigned Offset,
                                                uint64_t Address,
                                                const void *Decoder) {
  const MCDisassembler *Dis = static_cast<const MCDisassembler *>(Decoder);
  int32_t AdjustedOffset = SignExtend32<25>(Offset) * 4;
  if (!Dis->tryAddingSymbolicOperand(Inst, Address + AdjustedOffset,
                                     Address, true, 0, 25)) {
    Inst.addOperand(MCOperand::createImm(AdjustedOffset));
  }

  return MCDisassembler::Success;
}

DecodeStatus DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo,
                                      uint64_t Address, const void *Decoder) {

  if (RegNo > 31)
    return MCDisassembler::Fail;

  // The internal representation of the registers counts r0: 1, r1: 2, etc.
  Inst.addOperand(
      MCOperand::createReg(getReg(Decoder, Nyuzi::GPR32RegClassID, RegNo)));
  return MCDisassembler::Success;
}

DecodeStatus DecodeVR512RegisterClass(MCInst &Inst, unsigned RegNo,
                                      uint64_t Address, const void *Decoder) {

  if (RegNo > 31)
    return MCDisassembler::Fail;

  // The internal representation of the registers counts r0: 1, r1: 2, etc.
  Inst.addOperand(
      MCOperand::createReg(getReg(Decoder, Nyuzi::VR512RegClassID, RegNo)));
  return MCDisassembler::Success;
}
