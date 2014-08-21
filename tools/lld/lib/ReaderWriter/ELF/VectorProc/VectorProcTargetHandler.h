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
typedef llvm::object::ELFType<llvm::support::little, 4, false> VectorProcELFType;
class VectorProcLinkingContext;

class VectorProcTargetRelocationHandler final
    : public TargetRelocationHandler<VectorProcELFType> {
public:
  VectorProcTargetRelocationHandler(const VectorProcLinkingContext &context) {}
  virtual std::error_code applyRelocation(ELFWriter &, llvm::FileOutputBuffer &,
                                        const lld::AtomLayout &,
                                        const Reference &)const;
};

class VectorProcTargetHandler final
    : public DefaultTargetHandler<VectorProcELFType> {
public:
  VectorProcTargetHandler(VectorProcLinkingContext &context);

  virtual void registerRelocationNames(Registry &registry);

  virtual TargetLayout<VectorProcELFType> &getTargetLayout() {
    return _targetLayout;
  }

  virtual const VectorProcTargetRelocationHandler &getRelocationHandler() const {
    return _relocationHandler;
  }

  virtual std::unique_ptr<Writer> getWriter();

private:
  static const Registry::KindStrings kindStrings[];

  VectorProcTargetRelocationHandler _relocationHandler;
  TargetLayout<VectorProcELFType> _targetLayout;
  VectorProcLinkingContext &_linkingContext;
};
} // end namespace elf
} // end namespace lld

#endif
