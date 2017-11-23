//===-- NyuziTargetInfo.cpp - Nyuzi Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "Nyuzi.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

Target llvm::TheNyuziTarget;

extern "C" void LLVMInitializeNyuziTargetInfo() {
  RegisterTarget<Triple::nyuzi> X(TheNyuziTarget, "nyuzi", "Nyuzi", "Nyuzi");
}
