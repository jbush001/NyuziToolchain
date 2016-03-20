//===- NyuziDiagnostic.cpp ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "Nyuzi.h"
#include <mcld/LD/DWARFLineInfo.h>
#include <mcld/Support/TargetRegistry.h>

using namespace mcld;

namespace mcld {
//===----------------------------------------------------------------------===//
// createNyuziDiagnostic - the help function to create corresponding
// NyuziDiagnostic
//===----------------------------------------------------------------------===//
DiagnosticLineInfo* createNyuziDiagLineInfo(const mcld::Target& pTarget,
                                            const std::string& pTriple) {
  return new DWARFLineInfo();
}

}  // namespace of mcld

//===----------------------------------------------------------------------===//
// InitializeNyuziDiagnostic
//===----------------------------------------------------------------------===//
extern "C" void MCLDInitializeNyuziDiagnosticLineInfo() {
  // Register the linker frontend
  mcld::TargetRegistry::RegisterDiagnosticLineInfo(TheNyuziTarget,
                                                   createNyuziDiagLineInfo);
}
