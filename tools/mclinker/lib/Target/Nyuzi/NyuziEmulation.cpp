//===- NyuziEmulation.cpp -----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "Nyuzi.h"
#include <mcld/LinkerConfig.h>
#include <mcld/LinkerScript.h>
#include <mcld/Support/TargetRegistry.h>
#include <mcld/Target/ELFEmulation.h>

namespace mcld {

static bool MCLDEmulateNyuziELF(LinkerScript& pScript, LinkerConfig& pConfig) {
  if (!MCLDEmulateELF(pScript, pConfig)) return false;

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

  return true;
}

//===----------------------------------------------------------------------===//
// emulateNyuziLD - the help function to emulate Nyuzi ld
//===----------------------------------------------------------------------===//
bool emulateNyuziLD(LinkerScript& pScript, LinkerConfig& pConfig) {
  if (pConfig.targets().triple().isOSDarwin()) {
    assert(0 && "MachO linker has not supported");
    return false;
  }
  if (pConfig.targets().triple().isOSWindows()) {
    assert(0 && "COFF linker has not supported");
    return false;
  }

  return MCLDEmulateNyuziELF(pScript, pConfig);
}

}  // namespace of mcld

//===----------------------------------------------------------------------===//
// NyuziEmulation
//===----------------------------------------------------------------------===//
extern "C" void MCLDInitializeNyuziEmulation() {
  // Register the emulation
  mcld::TargetRegistry::RegisterEmulation(mcld::TheNyuziTarget,
                                          mcld::emulateNyuziLD);
}
