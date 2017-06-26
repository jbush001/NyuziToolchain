//===-- Nyuzi.h - Top-level interface for Nyuzi representation -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// Nyuzi back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZI_H
#define LLVM_LIB_TARGET_NYUZI_NYUZI_H

#include "llvm/Support/CodeGen.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class FunctionPass;
class NyuziTargetMachine;

FunctionPass *createNyuziISelDag(NyuziTargetMachine &TM);

} // namespace llvm

#endif
