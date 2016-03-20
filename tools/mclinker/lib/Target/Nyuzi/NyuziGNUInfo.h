//===- NyuziGNUInfo.h ---------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_NYUZI_NYUZIGNUINFO_H
#define TARGET_NYUZI_NYUZIGNUINFO_H
#include <mcld/Target/GNUInfo.h>

#include <llvm/Support/ELF.h>

namespace mcld {

class NyuziGNUInfo : public GNUInfo {
 public:
  NyuziGNUInfo(const llvm::Triple& pTriple) : GNUInfo(pTriple) {}

  uint32_t machine() const { return llvm::ELF::EM_NYUZI; }

  uint64_t abiPageSize() const { return 0x1000; }

  uint64_t defaultTextSegmentAddr() const { return 0; }

  // There are no processor-specific flags so this field shall contain zero.
  uint64_t flags() const { return 0x0; }
};

}  // namespace of mcld

#endif
