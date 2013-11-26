//===-- VectorProcMCAsmInfo.h - VectorProc asm properties ----------------*- C++
//-*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the VectorProcMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCTARGETASMINFO_H
#define VECTORPROCTARGETASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
class StringRef;
class Target;

class VectorProcMCAsmInfo : public MCAsmInfo {
  virtual void anchor();

public:
  explicit VectorProcMCAsmInfo(StringRef TT);
};

} // namespace llvm

#endif
