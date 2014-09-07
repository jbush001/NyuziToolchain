//===- VectorProcELFDynamic.cpp ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "VectorProcELFDynamic.h"

#include <mcld/LD/ELFFileFormat.h>
#include <mcld/LinkerConfig.h>

using namespace mcld;

VectorProcELFDynamic::VectorProcELFDynamic(const GNULDBackend& pParent,
                                     const LinkerConfig& pConfig)
  : ELFDynamic(pParent, pConfig)
{
}

VectorProcELFDynamic::~VectorProcELFDynamic()
{
}

void VectorProcELFDynamic::reserveTargetEntries(const ELFFileFormat& pFormat)
{
}

void VectorProcELFDynamic::applyTargetEntries(const ELFFileFormat& pFormat)
{
}

