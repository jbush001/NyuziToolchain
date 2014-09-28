//===- NyuziELFDynamic.h ------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_NYUZI_NYUZIELFDYNAMIC_H
#define TARGET_NYUZI_NYUZIELFDYNAMIC_H

#include <mcld/Target/ELFDynamic.h>

namespace mcld {

class NyuziELFDynamic : public ELFDynamic {
public:
  NyuziELFDynamic(const GNULDBackend& pParent, const LinkerConfig& pConfig);
  ~NyuziELFDynamic();

private:
  void reserveTargetEntries(const ELFFileFormat& pFormat);
  void applyTargetEntries(const ELFFileFormat& pFormat);
};

} // namespace of mcld

#endif
