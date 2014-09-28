//===- NyuziELFDynamic.cpp ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "NyuziELFDynamic.h"

#include <mcld/LD/ELFFileFormat.h>
#include <mcld/LinkerConfig.h>

using namespace mcld;

NyuziELFDynamic::NyuziELFDynamic(const GNULDBackend& pParent,
                                     const LinkerConfig& pConfig)
  : ELFDynamic(pParent, pConfig)
{
}

NyuziELFDynamic::~NyuziELFDynamic()
{
}

void NyuziELFDynamic::reserveTargetEntries(const ELFFileFormat& pFormat)
{
}

void NyuziELFDynamic::applyTargetEntries(const ELFFileFormat& pFormat)
{
}

