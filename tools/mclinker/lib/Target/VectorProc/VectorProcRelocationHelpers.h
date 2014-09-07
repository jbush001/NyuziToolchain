//===- VectorProcRelocationHelpers.h -----------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_VECTORPROC_VECTORPROCRELOCATIONHELPERS_H
#define TARGET_VECTORPROC_VECTORPROCRELOCATIONHELPERS_H

#include "VectorProcRelocator.h"
#include <llvm/Support/Host.h>

namespace mcld {
//===----------------------------------------------------------------------===//
// Relocation helper functions
//===----------------------------------------------------------------------===//

static inline uint32_t get_mask(uint32_t pValue)
{
  return ((1u << (pValue)) - 1);
}

static inline uint32_t
helper_replace_field(uint32_t instruction, uint32_t value, uint32_t offset, uint32_t size)
{
  return ((instruction & ~(get_mask(size) << offset)) | ((value & get_mask(size)) << offset));
}

}
#endif
