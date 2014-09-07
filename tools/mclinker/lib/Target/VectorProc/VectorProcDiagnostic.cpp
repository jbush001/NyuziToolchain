//===- VectorProcDiagnostic.cpp ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include <mcld/Support/TargetRegistry.h>
#include <mcld/LD/DWARFLineInfo.h>
#include "VectorProc.h"

using namespace mcld;

namespace mcld {
//===----------------------------------------------------------------------===//
// createVectorProcDiagnostic - the help function to create corresponding
// VectorProcDiagnostic
//===----------------------------------------------------------------------===//
DiagnosticLineInfo* createVectorProcDiagLineInfo(const mcld::Target& pTarget,
                                              const std::string &pTriple)
{
  return new DWARFLineInfo();
}

} // namespace of mcld

//===----------------------------------------------------------------------===//
// InitializeVectorProcDiagnostic
//===----------------------------------------------------------------------===//
extern "C" void MCLDInitializeVectorProcDiagnosticLineInfo() {
  // Register the linker frontend
  mcld::TargetRegistry::RegisterDiagnosticLineInfo(TheVectorProcTarget,
                                                   createVectorProcDiagLineInfo);
}

