//===-- VectorProcELFObjectWriter.cpp - VectorProc ELF Writer -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/VectorProcFixupKinds.h"
#include "MCTargetDesc/VectorProcMCTargetDesc.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
  class VectorProcELFObjectWriter : public MCELFObjectTargetWriter {
  public:
    VectorProcELFObjectWriter(uint8_t OSABI);

    virtual ~VectorProcELFObjectWriter();
  protected:
    virtual unsigned GetRelocType(const MCValue &Target, const MCFixup &Fixup,
                                  bool IsPCRel, bool IsRelocWithSymbol,
                                  int64_t Addend) const;
  };
}

VectorProcELFObjectWriter::VectorProcELFObjectWriter(uint8_t OSABI)
  : MCELFObjectTargetWriter(/*Is64Bit*/ false, OSABI, ELF::EM_VECTORPROC,
                            /*HasRelocationAddend*/ true) {}

VectorProcELFObjectWriter::~VectorProcELFObjectWriter() {}

unsigned VectorProcELFObjectWriter::GetRelocType(const MCValue &Target,
                                           const MCFixup &Fixup,
                                           bool IsPCRel,
                                           bool IsRelocWithSymbol,
                                           int64_t Addend) const 
{
	unsigned Type;
	unsigned Kind = (unsigned)Fixup.getKind();
	switch (Kind) {
		default: llvm_unreachable("Invalid fixup kind!");
		case VectorProc::fixup_VectorProc_Abs32:
			Type = ELF::R_VECTORPROC_ABS32;
			break;
	
		case VectorProc::fixup_VectorProc_PCRel_Branch:
			Type = ELF::R_VECTORPROC_BRANCH;
			break;
	}
	
	return Type;
}

MCObjectWriter *llvm::createVectorProcELFObjectWriter(raw_ostream &OS,
                                                uint8_t OSABI) {
  MCELFObjectTargetWriter *MOTW = new VectorProcELFObjectWriter(OSABI);
  return createELFObjectWriter(MOTW, OS, true);
}