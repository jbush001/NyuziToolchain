//===--- NyuziTargetObjectFile.h - Nyuzi Object Info ---------*- C++ ----*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file deals with any Nyuzi specific requirements on object files.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TARGET_NYUZI_NYUZITARGETOBJECTFILE_H
#define LLVM_TARGET_NYUZI_NYUZITARGETOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class TargetMachine;

class NyuziTargetObjectFile : public TargetLoweringObjectFileELF {
  void Initialize(MCContext &Ctx, const TargetMachine &TM) override;
  bool shouldPutJumpTableInFunctionSection(bool UsesLabelDifference,
                                           const Function &F) const override;
};

} // end namespace llvm

#endif
