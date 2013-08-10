//===-- VectorProcASMBackend.cpp - VectorProc Asm Backend  ----------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VectorProcAsmBackend class.
//
//===----------------------------------------------------------------------===//
//

#include "VectorProcFixupKinds.h"
#include "MCTargetDesc/VectorProcMCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

namespace {
class VectorProcAsmBackend : public MCAsmBackend {
  Triple::OSType OSType;

public:
  VectorProcAsmBackend(const Target &T,  Triple::OSType _OSType)
    :MCAsmBackend(), OSType(_OSType) {}

  MCObjectWriter *createObjectWriter(raw_ostream &OS) const {
    return createVectorProcELFObjectWriter(OS,
      MCELFObjectTargetWriter::getOSABI(OSType));
  }

  static unsigned adjustFixupValue(unsigned Kind, uint64_t Value) {
    switch (Kind)
    {
	  case VectorProc::fixup_VectorProc_PCRel_MemAccExt:
	  case VectorProc::fixup_VectorProc_PCRel_MemAcc:
	  case VectorProc::fixup_VectorProc_PCRel_Branch:
      case VectorProc::fixup_VectorProc_PCRel_ComputeLabelAddress:
	    Value -= 4;		// source location is PC + 4
		break;
    }
    
    return Value;
  }

  void applyFixup(const MCFixup &Fixup, char *Data, unsigned DataSize,
                  uint64_t Value) const 
  {
    MCFixupKind Kind = Fixup.getKind();
    Value = adjustFixupValue((unsigned)Kind, Value);
    unsigned Offset = Fixup.getOffset();
    unsigned NumBytes = 4;

    uint64_t CurVal = 0;
    for (unsigned i = 0; i != NumBytes; ++i) {
      CurVal |= (uint64_t)((uint8_t)Data[Offset + i]) << (i*8);
    }

    uint64_t Mask = ((uint64_t)(-1) >>
                     (64 - getFixupKindInfo(Kind).TargetSize));

	Value <<= getFixupKindInfo(Kind).TargetOffset;
	Mask <<= getFixupKindInfo(Kind).TargetOffset;
    CurVal |= Value & Mask;

    // Write out the fixed up bytes back to the code/data bits.
    for (unsigned i = 0; i != NumBytes; ++i) {
      Data[Offset + i] = (uint8_t)((CurVal >> (i*8)) & 0xff);
    }
  }

  unsigned getNumFixupKinds() const { return VectorProc::NumTargetFixupKinds; }

  const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const {
    const static MCFixupKindInfo Infos[VectorProc::NumTargetFixupKinds] = {
      // This table *must* be in same the order of fixup_* kinds in
      // VectorProcFixupKinds.h.
      //
      // name                          offset  bits  flags
      { "fixup_VectorProc_Abs32",           0,     32,   0 },
      { "fixup_VectorProc_PCRel_MemAccExt", 10,    15,   MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_VectorProc_PCRel_MemAcc",    15,    10,   MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_VectorProc_PCRel_Branch",    5,     20,   MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_VectorProc_PCRel_ComputeLabelAddress", 10, 13, MCFixupKindInfo::FKF_IsPCRel }
    };

    if (Kind < FirstTargetFixupKind)
      return MCAsmBackend::getFixupKindInfo(Kind);

    assert(unsigned(Kind - FirstTargetFixupKind) < getNumFixupKinds() &&
           "Invalid kind!");
    return Infos[Kind - FirstTargetFixupKind];
  }

  /// MayNeedRelaxation - Check whether the given instruction may need
  /// relaxation.
  ///
  /// \param Inst - The instruction to test.
  bool mayNeedRelaxation(const MCInst &Inst) const {
    return false;
  }

  /// fixupNeedsRelaxation - Target specific predicate for whether a given
  /// fixup requires the associated instruction to be relaxed.
  bool fixupNeedsRelaxation(const MCFixup &Fixup,
                            uint64_t Value,
                            const MCRelaxableFragment *DF,
                            const MCAsmLayout &Layout) const {
    // FIXME.
    assert(0 && "RelaxInstruction() unimplemented");
    return false;
  }

  /// RelaxInstruction - Relax the instruction in the given fragment
  /// to the next wider instruction.
  ///
  /// \param Inst - The instruction to relax, which may be the same
  /// as the output.
  /// \param [out] Res On return, the relaxed instruction.
  void relaxInstruction(const MCInst &Inst, MCInst &Res) const {
  }

  /// @}

  /// WriteNopData - Write an (optimal) nop sequence of Count bytes
  /// to the given output. If the target cannot generate such a sequence,
  /// it should return an error.
  ///
  /// \return - True on success.
  bool writeNopData(uint64_t Count, MCObjectWriter *OW) const {
    // Check for a less than instruction size number of bytes
    if (Count % 4) return false;

    uint64_t NumNops = Count / 4;
    for (uint64_t i = 0; i != NumNops; ++i)
      OW->Write32(0);
    return true;
  }
}; // class VectorProcAsmBackend

} // namespace

// MCAsmBackend
MCAsmBackend *llvm::createVectorProcAsmBackend(const Target &T, StringRef TT,
                                             StringRef CPU) {
  return new VectorProcAsmBackend(T, Triple(TT).getOS());
}

