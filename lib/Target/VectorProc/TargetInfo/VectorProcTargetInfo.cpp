//===-- VectorProcTargetInfo.cpp - VectorProc Target Implementation
//-----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "VectorProc.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheVectorProcTarget;

extern "C" void LLVMInitializeVectorProcTargetInfo() {
  RegisterTarget<Triple::vectorproc> X(TheVectorProcTarget, "vectorproc",
                                       "VectorProc");
}
