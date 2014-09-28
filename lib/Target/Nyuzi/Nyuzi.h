//===-- Nyuzi.h - Top-level interface for Nyuzi representation --*-
//C++ -*-===//
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

#ifndef TARGET_NYUZI_H
#define TARGET_NYUZI_H

#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class FunctionPass;
class NyuziTargetMachine;
class formatted_raw_ostream;

FunctionPass *createNyuziISelDag(NyuziTargetMachine &TM);

} // end namespace llvm;

#endif
