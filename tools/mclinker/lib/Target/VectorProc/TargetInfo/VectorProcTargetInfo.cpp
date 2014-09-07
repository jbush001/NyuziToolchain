//===- VectorProcTargetInfo.cpp ----------------------------------------------===//
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

mcld::Target TheVectorProcTarget;

extern "C" void MCLDInitializeVectorProcLDTargetInfo() {
  // register into mcld::TargetRegistry
  mcld::RegisterTarget<llvm::Triple::vectorproc> X(TheVectorProcTarget, "vectorproc");
}

} // namespace of mcld

