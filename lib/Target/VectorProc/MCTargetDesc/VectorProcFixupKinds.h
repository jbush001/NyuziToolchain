//===-- MipsFixupKinds.h - Mips Specific Fixup Entries ----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_MIPS_VECTORPROCFIXUPKINDS_H
#define LLVM_MIPS_VECTORPROCFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace VectorProc {
  // Although most of the current fixup types reflect a unique relocation
  // one can have multiple fixup types for a given relocation and thus need
  // to be uniquely named.
  //
  // This table *must* be in the save order of
  // MCFixupKindInfo Infos[VectorProc::NumTargetFixupKinds]
  // in VectorProcAsmBackend.cpp.
  //
  enum Fixups {
    fixup_VectorProc_Abs32 = FirstTargetFixupKind,	// Pure 32-bit absolute fixup
    fixup_VectorProc_PCRel_MemAccExt,	// PC relative offset for extended memory access
    fixup_VectorProc_PCRel_MemAcc,		// PC relative offset for memory access
    fixup_VectorProc_PCRel_Branch,		// PC relative for branch instruction
    fixup_VectorProc_PCRel_ComputeLabelAddress, // For getting jump table addresses

    // Marker
    LastTargetFixupKind,
    NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
  };
} // namespace VectorProc
} // namespace llvm


#endif // LLVM_MIPS_VECTORPROCFIXUPKINDS_H
