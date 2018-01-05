//===-- NyuziFixupKinds.h - Nyuzi Specific Fixup Entries -------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIFIXUPKINDS_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace Nyuzi {
// Although most of the current fixup types reflect a unique relocation
// one can have multiple fixup types for a given relocation and thus need
// to be uniquely named.
//
// This table *must* be in the save order of
// MCFixupKindInfo Infos[Nyuzi::NumTargetFixupKinds]
// in NyuziAsmBackend.cpp.
//
enum Fixups {
  fixup_Nyuzi_Branch20 = FirstTargetFixupKind,
  fixup_Nyuzi_Branch25,
  fixup_Nyuzi_HI19,                         // Fix up 19 bit movehi value
  fixup_Nyuzi_IMM_LO13,                     // Immediate instruction w/ 13 bit offs
  fixup_Nyuzi_GOT,

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // namespace Nyuzi
} // namespace llvm

#endif // LLVM_NYUZI_NYUZIFIXUPKINDS_H
