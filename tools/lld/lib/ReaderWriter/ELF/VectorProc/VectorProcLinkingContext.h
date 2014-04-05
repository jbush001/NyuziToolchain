//===- lib/ReaderWriter/ELF/Hexagon/VectorProcLinkingContext.h -----------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLD_READER_WRITER_ELF_VECTORPROC_LINKING_CONTEXT_H
#define LLD_READER_WRITER_ELF_VECTORPROC_LINKING_CONTEXT_H

#include "VectorProcTargetHandler.h"

#include "lld/ReaderWriter/ELFLinkingContext.h"

#include "llvm/Object/ELF.h"
#include "llvm/Support/ELF.h"

namespace lld {
namespace elf {
class VectorProcLinkingContext final : public ELFLinkingContext {
public:
  VectorProcLinkingContext(llvm::Triple triple)
    : ELFLinkingContext(triple, std::unique_ptr<TargetHandlerBase>(new VectorProcTargetHandler(*this))) {}

  virtual bool isLittleEndian() const { return true; }

  virtual bool isRelativeReloc(const Reference &ref) const { 
  	return ref.kindValue() == R_VECTORPROC_BRANCH; 
  }

  virtual uint64_t getPageSize() const { 
    return 64; 
  }
};

} // elf
} // lld

#endif // LLD_READER_WRITER_ELF_VectorProc_TARGETINFO_H
