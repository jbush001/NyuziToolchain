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

static inline bool
helper_check_signed_overflow(Relocator::DWord pValue, unsigned bits)
{
  if (bits >= sizeof(int64_t) * 8)
    return false;
  int64_t signed_val = static_cast<int64_t>(pValue);
  int64_t max = (1 << (bits - 1)) - 1;
  int64_t min = -(1 << (bits - 1));
  if (signed_val > max || signed_val < min)
    return true;
  return false;
}

static inline uint32_t
helper_replace_field(uint32_t instruction, uint32_t value, uint32_t offset, uint32_t size)
{
  return ((instruction & ~(get_mask(size) << offset)) | ((value & get_mask(size)) << offset));
}

}
#endif
