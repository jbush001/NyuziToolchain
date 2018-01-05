//===-- NyuziBaseInfo.h - Top level definitions for Nyuzi MC ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the Nyuzi target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_MCTARGETDESC_NYUZIBASEINFO_H
#define LLVM_LIB_TARGET_NYUZI_MCTARGETDESC_NYUZIBASEINFO_H

namespace llvm {

namespace Nyuzi {
// Target Operand Flag enum.
enum TOF {
  //===------------------------------------------------------------------===//
  MO_NO_FLAG,

  // MO_ABS_HI/LO - Represents the hi or low part of an absolute symbol
  // address.
  MO_ABS_HI,
  MO_ABS_LO,
  MO_GOT
};
} // namespace Nyuzi
} // namespace llvm
#endif // LLVM_LIB_TARGET_NYUZI_MCTARGETDESC_NYUZIBASEINFO_H
