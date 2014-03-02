//===-- VectorProc.h - Top-level interface for VectorProc representation --*-
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
// VectorProc back-end.
//
//===----------------------------------------------------------------------===//

#ifndef TARGET_VECTORPROC_H
#define TARGET_VECTORPROC_H

#include "MCTargetDesc/VectorProcMCTargetDesc.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class FunctionPass;
class VectorProcTargetMachine;
class formatted_raw_ostream;

FunctionPass *createVectorProcISelDag(VectorProcTargetMachine &TM);

} // end namespace llvm;

#endif
