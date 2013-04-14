//===-- VectorProcMCAsmInfo.h - VectorProc asm properties ----------------*- C++ -*--===//
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

  class VectorProcELFMCAsmInfo : public MCAsmInfo {
    virtual void anchor();
  public:
    explicit VectorProcELFMCAsmInfo(const Target &T, StringRef TT);
  };

} // namespace llvm

#endif
