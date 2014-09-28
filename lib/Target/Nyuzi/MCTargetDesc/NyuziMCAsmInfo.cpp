//===-- NyuziMCAsmInfo.cpp - Nyuzi asm properties
//-------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the NyuziMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "NyuziMCAsmInfo.h"
#include "llvm/ADT/Triple.h"

using namespace llvm;

void NyuziMCAsmInfo::anchor() {}

NyuziMCAsmInfo::NyuziMCAsmInfo(StringRef TT) {
  IsLittleEndian = true;
  CommentString = ";";
  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::None;
  PrivateGlobalPrefix = ".L";
}
