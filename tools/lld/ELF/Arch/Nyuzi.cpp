
//===- Nyuzi.cpp ----------------------------------------------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Error.h"
#include "InputFiles.h"
#include "Symbols.h"
#include "SyntheticSections.h"
#include "Target.h"
#include "Thunks.h"
#include "llvm/Object/ELF.h"
#include "llvm/Support/Endian.h"

using namespace llvm;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

namespace {

class Nyuzi final : public TargetInfo {
public:
  Nyuzi();
  void relocateOne(uint8_t *Loc, uint32_t Type, uint64_t Val) const override;
  RelExpr getRelExpr(uint32_t Type, const SymbolBody &S, const InputFile &File,
                     const uint8_t *Loc) const override;
};

template <uint8_t SIZE, uint8_t BASE>
void applyNyuziReloc(uint8_t *Loc, uint32_t Type, uint64_t V) {
  uint32_t Mask = (0xffffffff >> (32 - SIZE)) << BASE;
  write32le(Loc, (read32le(Loc) & ~Mask) | ((V << BASE) & Mask));
}
} // namespace

Nyuzi::Nyuzi() {
  PageSize = 0x1000;
  DefaultImageBase = 0;
}

void Nyuzi::relocateOne(uint8_t *Loc, uint32_t Type, uint64_t Val) const {
  int64_t Offset;
  switch (Type) {
  default:
    fatal("unrecognized reloc " + Twine(Type));
  case R_NYUZI_ABS32:
    write32le(Loc, Val);
    break;
  case R_NYUZI_BRANCH20:
    Offset = static_cast<int64_t>(Val) / 4;
    checkInt<20>(Loc, Offset, Type);
    applyNyuziReloc<20, 5>(Loc, Type, Offset);
    break;
  case R_NYUZI_BRANCH25:
    Offset = static_cast<int64_t>(Val) / 4;
    checkInt<25>(Loc, Offset, Type);
    applyNyuziReloc<25, 0>(Loc, Type, Offset);
    break;
  case R_NYUZI_HI19:
    applyNyuziReloc<5, 0>(Loc, Type, (Val >> 13) & 0x1f);
    applyNyuziReloc<14, 10>(Loc, Type, (Val >> 18) & 0x3fff);
    break;
  case R_NYUZI_IMM_LO13:
    applyNyuziReloc<13, 10>(Loc, Type, Val & 0x1fff);
    break;
  }
}

RelExpr Nyuzi::getRelExpr(uint32_t Type, const SymbolBody &S,
                          const InputFile &File, const uint8_t *Loc) const {
  switch (Type) {
  default:
    fatal("unrecognized reloc " + Twine(Type));
  case R_NYUZI_ABS32:
  case R_NYUZI_IMM_LO13:
  case R_NYUZI_HI19:
    return R_ABS;

  case R_NYUZI_BRANCH20:
  case R_NYUZI_BRANCH25:
    return R_PC;
  }
}

TargetInfo *elf::getNyuziTargetInfo() {
  static Nyuzi Target;
  return &Target;
}
