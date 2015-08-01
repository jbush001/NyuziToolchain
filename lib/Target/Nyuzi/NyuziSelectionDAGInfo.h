//===-- NyuziSelectionDAGInfo.h - Nyuzi SelectionDAG Info ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the Nyuzi subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef NYUZISELECTIONDAGINFO_H
#define NYUZISELECTIONDAGINFO_H

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class NyuziTargetMachine;

class NyuziSelectionDAGInfo : public TargetSelectionDAGInfo {
public:
  explicit NyuziSelectionDAGInfo();
  ~NyuziSelectionDAGInfo();
};
}

#endif
