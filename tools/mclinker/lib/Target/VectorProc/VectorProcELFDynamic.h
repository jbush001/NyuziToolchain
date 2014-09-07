//===- VectorProcELFDynamic.h ------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_VECTORPROC_VECTORPROCELFDYNAMIC_H
#define TARGET_VECTORPROC_VECTORPROCELFDYNAMIC_H

#include <mcld/Target/ELFDynamic.h>

namespace mcld {

class VectorProcELFDynamic : public ELFDynamic {
public:
  VectorProcELFDynamic(const GNULDBackend& pParent, const LinkerConfig& pConfig);
  ~VectorProcELFDynamic();

private:
  void reserveTargetEntries(const ELFFileFormat& pFormat);
  void applyTargetEntries(const ELFFileFormat& pFormat);
};

} // namespace of mcld

#endif
