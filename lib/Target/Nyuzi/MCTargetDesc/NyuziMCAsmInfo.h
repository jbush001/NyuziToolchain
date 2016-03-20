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

#ifndef NYUZITARGETASMINFO_H
#define NYUZITARGETASMINFO_H

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
