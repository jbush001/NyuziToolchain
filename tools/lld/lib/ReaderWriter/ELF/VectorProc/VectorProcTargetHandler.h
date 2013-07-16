//===- lib/ReaderWriter/ELF/VectorProc/VectorProcTargetHandler.h ------------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLD_READER_WRITER_ELF_VectorProc_TARGET_HANDLER_H
#define LLD_READER_WRITER_ELF_VectorProc_TARGET_HANDLER_H

#include "DefaultTargetHandler.h"
#include "TargetLayout.h"

namespace lld {
namespace elf {
typedef llvm::object::ELFType<llvm::support::big, 4, false> VectorProcELFType;
class VectorProcTargetInfo;

class VectorProcTargetRelocationHandler LLVM_FINAL
    : public TargetRelocationHandler<VectorProcELFType> {
public:
  VectorProcTargetRelocationHandler(const VectorProcTargetInfo &ti) : _targetInfo(ti) {}

  virtual ErrorOr<void> applyRelocation(ELFWriter &, llvm::FileOutputBuffer &,
                                        const lld::AtomLayout &,
                                        const Reference &)const;

private:
  const VectorProcTargetInfo &_targetInfo;
};

class VectorProcTargetHandler LLVM_FINAL
    : public DefaultTargetHandler<VectorProcELFType> {
public:
  VectorProcTargetHandler(VectorProcTargetInfo &targetInfo);

  virtual TargetLayout<VectorProcELFType> &targetLayout() {
    return _targetLayout;
  }

  virtual const VectorProcTargetRelocationHandler &getRelocationHandler() const {
    return _relocationHandler;
  }

private:
  VectorProcTargetRelocationHandler _relocationHandler;
  TargetLayout<VectorProcELFType> _targetLayout;
};
} // end namespace elf
} // end namespace lld

#endif
