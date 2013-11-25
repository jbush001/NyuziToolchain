//===-- VectorProcMCAsmInfo.cpp - VectorProc asm properties -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the VectorProcMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "VectorProcMCAsmInfo.h"
#include "llvm/ADT/Triple.h"

using namespace llvm;

void VectorProcMCAsmInfo::anchor() { }

VectorProcMCAsmInfo::VectorProcMCAsmInfo(StringRef TT) {
  IsLittleEndian = true;
  Triple TheTriple(TT);

  Data16bitsDirective = "\t.short\t";
  Data32bitsDirective = "\t.word\t";
  Data64bitsDirective = 0;
  ZeroDirective = "";	// What is this?
  CommentString = ";";
  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::None;

  WeakRefDirective = "";

  PrivateGlobalPrefix = "L";
}


