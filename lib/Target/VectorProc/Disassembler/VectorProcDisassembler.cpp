//===- VectorProcDisassembler.cpp - Disassembler for VectorProc -------------*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is part of the VectorProc Disassembler.
//
//===----------------------------------------------------------------------===//

#include "VectorProc.h"
#include "VectorProcRegisterInfo.h"
#include "VectorProcSubtarget.h"
#include "llvm/MC/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/MemoryObject.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {

/// VectorProcDisassembler - a disasembler class for VectorProc32.
class VectorProcDisassembler : public MCDisassembler {
public:
  /// Constructor     - Initializes the disassembler.
  ///
  VectorProcDisassembler(const MCSubtargetInfo &STI, const MCRegisterInfo *Info)
      : MCDisassembler(STI), RegInfo(Info) {}

  const MCRegisterInfo *getRegInfo() const { return RegInfo; }

  /// getInstruction - See MCDisassembler.
  virtual DecodeStatus getInstruction(MCInst &instr, uint64_t &size,
                                      const MemoryObject &region,
                                      uint64_t address, raw_ostream &vStream,
                                      raw_ostream &cStream) const;

private:
  const MCRegisterInfo *RegInfo;
};

} // end anonymous namespace

static DecodeStatus decodeScalarMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder);

static DecodeStatus decodeVectorMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder);

static DecodeStatus decodeBranchTargetOpValue(MCInst &Inst, unsigned Insn,
                                            uint64_t Address,
                                            const void *Decoder);

DecodeStatus DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo,
                                          uint64_t Address,
                                          const void *Decoder);

DecodeStatus DecodeVR512RegisterClass(MCInst &Inst, unsigned RegNo,
                                          uint64_t Address,
                                          const void *Decoder);

namespace llvm {
extern Target TheVectorProcelTarget, TheVectorProcTarget, TheVectorProc64Target,
    TheVectorProc64elTarget;
}

static MCDisassembler *
createVectorProcDisassembler(const Target &T, const MCSubtargetInfo &STI) {
  return new VectorProcDisassembler(STI, T.createMCRegInfo(""));
}

extern "C" void LLVMInitializeVectorProcDisassembler() {
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(TheVectorProcTarget,
                                         createVectorProcDisassembler);
}

#include "VectorProcGenDisassemblerTables.inc"

/// readInstruction - read four bytes from the MemoryObject
/// and return 32 bit word sorted according to the given endianess
static DecodeStatus readInstruction32(const MemoryObject &region,
                                      uint64_t address, uint64_t &size,
                                      uint32_t &insn) {
  uint8_t Bytes[4];

  // We want to read exactly 4 Bytes of data.
  if (region.readBytes(address, 4, Bytes) == -1) {
    size = 0;
    return MCDisassembler::Fail;
  }

  insn =
      (Bytes[0] << 0) | (Bytes[1] << 8) | (Bytes[2] << 16) | (Bytes[3] << 24);

  return MCDisassembler::Success;
}

DecodeStatus VectorProcDisassembler::getInstruction(
    MCInst &instr, uint64_t &Size, const MemoryObject &Region, uint64_t Address,
    raw_ostream &vStream, raw_ostream &cStream) const {
  uint32_t Insn;

  DecodeStatus Result = readInstruction32(Region, Address, Size, Insn);
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
  const VectorProcDisassembler *Dis =
      static_cast<const VectorProcDisassembler *>(D);
  return *(Dis->getRegInfo()->getRegClass(RC).begin() + RegNo);
}

static DecodeStatus decodeMemoryOpValue(MCInst &Inst, unsigned Insn,
                                        uint64_t Address, const void *Decoder,
                                        unsigned RC) {
  // XXX this depends on the instruction type (has mask or not)
  int Offset = SignExtend32<15>(fieldFromInstruction(Insn, 5, 15));
  int RegisterIndex = fieldFromInstruction(Insn, 0, 5);
  unsigned BaseReg = getReg(Decoder, RC, RegisterIndex);

  Inst.addOperand(MCOperand::CreateReg(BaseReg));
  Inst.addOperand(MCOperand::CreateImm(Offset));
  
  return MCDisassembler::Success;
}

static DecodeStatus decodeScalarMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder) {
  return decodeMemoryOpValue(Inst, Insn, Address, Decoder,
                             VectorProc::GPR32RegClassID);
}

static DecodeStatus decodeVectorMemoryOpValue(MCInst &Inst, unsigned Insn,
                                              uint64_t Address,
                                              const void *Decoder) {
  return decodeMemoryOpValue(Inst, Insn, Address, Decoder,
                             VectorProc::VR512RegClassID);
}

static DecodeStatus decodeBranchTargetOpValue(MCInst &Inst, unsigned Insn,
                                            uint64_t Address,
                                            const void *Decoder) {
  const MCDisassembler *Dis = static_cast<const MCDisassembler*>(Decoder);
  if (!Dis->tryAddingSymbolicOperand(Inst, Address + 4 + SignExtend32<20>(Insn), 
    Address, true, 0, 4))
  {
    Inst.addOperand(MCOperand::CreateImm(SignExtend32<20>(Insn)));
  }

  return MCDisassembler::Success;
}

DecodeStatus DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo,
                                          uint64_t Address,
                                          const void *Decoder) {

  if (RegNo > 31)
    return MCDisassembler::Fail;

  // The internal representation of the registers counts r0: 1, r1: 2, etc.
  Inst.addOperand(MCOperand::CreateReg(
      getReg(Decoder, VectorProc::GPR32RegClassID, RegNo)));
  return MCDisassembler::Success;
}

DecodeStatus DecodeVR512RegisterClass(MCInst &Inst, unsigned RegNo,
                                          uint64_t Address,
                                          const void *Decoder) {

  if (RegNo > 31)
    return MCDisassembler::Fail;

  // The internal representation of the registers counts r0: 1, r1: 2, etc.
  Inst.addOperand(MCOperand::CreateReg(
      getReg(Decoder, VectorProc::VR512RegClassID, RegNo)));
  return MCDisassembler::Success;
}
