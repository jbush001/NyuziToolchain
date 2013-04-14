//===-- VectorProcSelectionDAGInfo.cpp - VectorProc SelectionDAG Info ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the VectorProcSelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "vectorproc-selectiondag-info"
#include "VectorProcTargetMachine.h"
using namespace llvm;

VectorProcSelectionDAGInfo::VectorProcSelectionDAGInfo(const VectorProcTargetMachine &TM)
  : TargetSelectionDAGInfo(TM) {
}

VectorProcSelectionDAGInfo::~VectorProcSelectionDAGInfo() {
}
