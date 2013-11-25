//===-- VectorProcTargetObjectFile.cpp - VectorProc Object Info -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file deals with any VectorProc specific requirements on object files.
//
//===----------------------------------------------------------------------===//


#include "VectorProcTargetObjectFile.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

void
VectorProcTargetObjectFile::Initialize(MCContext &Ctx,
                                       const TargetMachine &TM) {
  TargetLoweringObjectFileELF::Initialize(Ctx, TM);
  InitializeELF(TM.Options.UseInitArray);
}
