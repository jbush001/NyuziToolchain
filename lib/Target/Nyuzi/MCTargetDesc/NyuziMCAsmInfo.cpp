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
  PrivateGlobalPrefix = ".L";
  PrivateLabelPrefix = ".L";

  // The C++ frontend has exceptions disabled. However, the compiler
  // will not emit debug frame info unless this is set to DwarfCFI.
  ExceptionsType = ExceptionHandling::DwarfCFI;
}
