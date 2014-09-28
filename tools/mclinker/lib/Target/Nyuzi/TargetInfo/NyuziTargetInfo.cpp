//===- NyuziTargetInfo.cpp ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <mcld/Support/TargetRegistry.h>
#include <mcld/Support/Target.h>

namespace mcld {

mcld::Target TheNyuziTarget;

extern "C" void MCLDInitializeNyuziLDTargetInfo() {
  // register into mcld::TargetRegistry
  mcld::RegisterTarget<llvm::Triple::nyuzi> X(TheNyuziTarget, "nyuzi");
}

} // namespace of mcld

