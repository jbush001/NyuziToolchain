//===-- NyuziELFObjectWriter.cpp - Nyuzi ELF Writer ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/NyuziFixupKinds.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
class NyuziELFObjectWriter : public MCELFObjectTargetWriter {
public:
  explicit NyuziELFObjectWriter(uint8_t OSABI);

protected:
  unsigned getRelocType(MCContext &Ctx, const MCValue &Target,
                        const MCFixup &Fixup, bool IsPCRel) const override;
};
} // namespace

NyuziELFObjectWriter::NyuziELFObjectWriter(uint8_t OSABI)
    : MCELFObjectTargetWriter(/*Is64Bit*/ false, OSABI, ELF::EM_NYUZI,
                              /*HasRelocationAddend*/ true) {}

unsigned NyuziELFObjectWriter::getRelocType(MCContext &Ctx,
                                            const MCValue &Target,
                                            const MCFixup &Fixup,
                                            bool IsPCRel) const {
  unsigned Type;
  unsigned Kind = (unsigned)Fixup.getKind();
  switch (Kind) {
  default:
    llvm_unreachable("Invalid fixup kind!");
  case FK_Data_4:
    Type = ELF::R_NYUZI_ABS32;
    break;

  case Nyuzi::fixup_Nyuzi_Branch20:
    assert(IsPCRel);
    Type = ELF::R_NYUZI_BRANCH20;
    break;

  case Nyuzi::fixup_Nyuzi_Branch25:
    assert(IsPCRel);
    Type = ELF::R_NYUZI_BRANCH25;
    break;

  case Nyuzi::fixup_Nyuzi_HI19:
    assert(!IsPCRel);
    Type = ELF::R_NYUZI_HI19;
    break;

  case Nyuzi::fixup_Nyuzi_IMM_LO13:
    assert(!IsPCRel);
    Type = ELF::R_NYUZI_IMM_LO13;
    break;
  }
  return Type;
}

std::unique_ptr<MCObjectWriter>
llvm::createNyuziELFObjectWriter(raw_pwrite_stream &OS,
                                 uint8_t OSABI) {
  return createELFObjectWriter(llvm::make_unique<NyuziELFObjectWriter>(OSABI),
                               OS, true);
}
