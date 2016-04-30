//===-- NyuziMCAsmInfo.h - Nyuzi asm properties ----------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the NyuziMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIMCASMINFO_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIMCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;

class NyuziMCAsmInfo : public MCAsmInfo {
  virtual void anchor();

public:
  explicit NyuziMCAsmInfo(const Triple &TT);
};

} // namespace llvm

#endif
