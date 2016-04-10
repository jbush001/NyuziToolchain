//===-- MipsFixupKinds.h - Mips Specific Fixup Entries ----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_MIPS_NYUZIFIXUPKINDS_H
#define LLVM_MIPS_NYUZIFIXUPKINDS_H

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
  fixup_Nyuzi_PCRel_MemAccExt = FirstTargetFixupKind, // PC relative offset
                                                      // for extended memory
                                                      // access
  fixup_Nyuzi_PCRel_MemAcc,              // PC relative offset for memory access
  fixup_Nyuzi_PCRel_Branch,              // PC relative for branch instruction
  fixup_Nyuzi_PCRel_ComputeLabelAddress, // For getting jump table
                                         // addresses

  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // namespace Nyuzi
} // namespace llvm

#endif // LLVM_MIPS_NYUZIFIXUPKINDS_H
