//===- VectorProcEmulation.cpp -----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "VectorProc.h"
#include <mcld/LinkerConfig.h>
#include <mcld/LinkerScript.h>
#include <mcld/Target/ELFEmulation.h>
#include <mcld/Support/TargetRegistry.h>

namespace mcld {

static bool MCLDEmulateVectorProcELF(LinkerScript& pScript, LinkerConfig& pConfig)
{
  if (!MCLDEmulateELF(pScript, pConfig))
    return false;

  // set up bitclass and endian
  pConfig.targets().setEndian(TargetOptions::Little);
  pConfig.targets().setBitClass(32);

  // set up target-dependent constraints of attributes
  pConfig.attribute().constraint().enableWholeArchive();
  pConfig.attribute().constraint().enableAsNeeded();
  pConfig.attribute().constraint().setSharedSystem();

  // set up the predefined attributes
  pConfig.attribute().predefined().unsetWholeArchive();
  pConfig.attribute().predefined().unsetAsNeeded();

  // set up section map
  if (pConfig.options().getScriptList().empty() &&
      pConfig.codeGenType() != LinkerConfig::Object) {
    pScript.sectionMap().insert(".ARM.attributes*", ".ARM.attributes");
  }
  return true;
}

//===----------------------------------------------------------------------===//
// emulateVectorProcLD - the help function to emulate VectorProc ld
//===----------------------------------------------------------------------===//
bool emulateVectorProcLD(LinkerScript& pScript, LinkerConfig& pConfig)
{
  if (pConfig.targets().triple().isOSDarwin()) {
    assert(0 && "MachO linker has not supported");
    return false;
  }
  if (pConfig.targets().triple().isOSWindows()) {
    assert(0 && "COFF linker has not supported");
    return false;
  }

  return MCLDEmulateVectorProcELF(pScript, pConfig);
}

} // namespace of mcld

//===----------------------------------------------------------------------===//
// VectorProcEmulation
//===----------------------------------------------------------------------===//
extern "C" void MCLDInitializeVectorProcEmulation() {
  // Register the emulation
  mcld::TargetRegistry::RegisterEmulation(mcld::TheVectorProcTarget,
                                          mcld::emulateVectorProcLD);
}

