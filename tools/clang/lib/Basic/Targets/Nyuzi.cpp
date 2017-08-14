//===--- Nyuzi.cpp - Implement Nyuzi target feature support ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements Nyuzi TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/ADT/StringSwitch.h"
#include "Nyuzi.h"

using namespace clang;
using namespace clang::targets;

const char *const NyuziTargetInfo::GCCRegNames[] = {
  "s0",  "s1",  "s2",  "s3",  "s4",  "s5",  "s6",  "s7",
  "s8",  "s9",  "s10", "s11", "s12", "s13", "s14", "s15",
  "s16",  "s17",  "s18",  "s19",  "s20",  "s21",  "s22",  "s23",
  "s24",  "s25",  "s26", "s27", "s28", "fp", "sp", "ra",
  "v0",  "v1",  "v2",  "v3",  "v4",  "v5",  "v6",  "v7",
  "v8",  "v9",  "v10", "v11", "v12", "v13", "v14", "v15",
  "v16",  "v17",  "v18",  "v19",  "v20",  "v21",  "v22",  "v23",
  "v24",  "v25",  "v26", "v27", "v28", "v29", "v30", "v31",
};

const Builtin::Info NyuziTargetInfo::BuiltinInfo[] = {
#define BUILTIN(ID, TYPE, ATTRS) { #ID, TYPE, ATTRS, 0, ALL_LANGUAGES },
#define LIBBUILTIN(ID, TYPE, ATTRS, HEADER) { #ID, TYPE, ATTRS, HEADER,\
                                              ALL_LANGUAGES },
#include "clang/Basic/BuiltinsNyuzi.def"
};

ArrayRef<const char *> NyuziTargetInfo::getGCCRegNames() const {
  return llvm::makeArrayRef(GCCRegNames);
}

bool NyuziTargetInfo::
validateAsmConstraint(const char *&Name,
                      TargetInfo::ConstraintInfo &Info) const {
  switch (*Name) {
  default:
    return false;

  case 's':
  case 'v':
    Info.setAllowsRegister();
    return true;

  case 'I': // Unsigned 8-bit constant
  case 'J': // Unsigned 12-bit constant
  case 'K': // Signed 16-bit constant
  case 'L': // Signed 20-bit displacement (on all targets we support)
  case 'M': // 0x7fffffff
    return true;

  case 'Q': // Memory with base and unsigned 12-bit displacement
  case 'R': // Likewise, plus an index
  case 'S': // Memory with base and signed 20-bit displacement
  case 'T': // Likewise, plus an index
    Info.setAllowsMemory();
    return true;
  }
}

ArrayRef<Builtin::Info> NyuziTargetInfo::getTargetBuiltins() const {
  return llvm::makeArrayRef(BuiltinInfo,
                        clang::Nyuzi::LastTSBuiltin - Builtin::FirstTSBuiltin);
}

