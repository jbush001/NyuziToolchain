//===-- VectorProcSelectionDAGInfo.h - VectorProc SelectionDAG Info -------*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the VectorProc subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCSELECTIONDAGINFO_H
#define VECTORPROCSELECTIONDAGINFO_H

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class VectorProcTargetMachine;

class VectorProcSelectionDAGInfo : public TargetSelectionDAGInfo {
public:
  explicit VectorProcSelectionDAGInfo(const VectorProcTargetMachine &TM);
  ~VectorProcSelectionDAGInfo();
};
}

#endif
