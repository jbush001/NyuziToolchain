//===- lib/ReaderWriter/ELF/Hexagon/VectorProcTargetInfo.h -----------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLD_READER_WRITER_ELF_VECTORPROC_TARGETINFO_H
#define LLD_READER_WRITER_ELF_VECTORPROC_TARGETINFO_H

#include "VectorProcTargetHandler.h"

#include "lld/ReaderWriter/ELFTargetInfo.h"

#include "llvm/Object/ELF.h"
#include "llvm/Support/ELF.h"

namespace lld {
namespace elf {
class VectorProcTargetInfo LLVM_FINAL : public ELFTargetInfo {
public:
  VectorProcTargetInfo(llvm::Triple triple)
    : ELFTargetInfo(triple, std::unique_ptr<TargetHandlerBase>(new VectorProcTargetHandler(*this))) {}

  virtual bool isLittleEndian() const { return true; }

  virtual bool isRelativeReloc(const Reference &ref) const { 
  	return ref.kind() == R_VECTORPROC_BRANCH; 
  }

  virtual ErrorOr<Reference::Kind> relocKindFromString(StringRef str) const;
  virtual ErrorOr<std::string> stringFromRelocKind(Reference::Kind kind) const;
};

} // elf
} // lld

#endif // LLD_READER_WRITER_ELF_VectorProc_TARGETINFO_H
