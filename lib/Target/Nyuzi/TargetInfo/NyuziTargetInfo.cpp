//===-- NyuziTargetInfo.cpp - Nyuzi Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Nyuzi.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"

using namespace llvm;

Target llvm::TheNyuziTarget;

extern "C" void LLVMInitializeNyuziTargetInfo() {
  RegisterTarget<Triple::nyuzi> X(TheNyuziTarget, "nyuzi", "Nyuzi");
}
