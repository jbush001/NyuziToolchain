//===-  NyuziRelocator.h ------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_NYUZI_NYUZIRELOCATOR_H
#define TARGET_NYUZI_NYUZIRELOCATOR_H

#include <mcld/LD/Relocator.h>
#include <mcld/Target/GOT.h>
#include <mcld/Target/KeyEntryMap.h>
#include "NyuziLDBackend.h"

namespace mcld {

/** \class NyuziRelocator
 *  \brief NyuziRelocator creates and destroys the Nyuzi relocations.
 *
 */
class NyuziRelocator : public Relocator
{
public:
  typedef KeyEntryMap<Relocation, Relocation> RelRelMap;


public:
  NyuziRelocator(NyuziGNULDBackend& pParent, const LinkerConfig& pConfig);
  ~NyuziRelocator();

  Result applyRelocation(Relocation& pRelocation);

  NyuziGNULDBackend& getTarget()
  { return m_Target; }

  const NyuziGNULDBackend& getTarget() const
  { return m_Target; }

  const char* getName(Relocation::Type pType) const;

  Size getSize(Relocation::Type pType) const;

  const RelRelMap& getRelRelMap() const { return m_RelRelMap; }
  RelRelMap&       getRelRelMap()       { return m_RelRelMap; }

  void scanRelocation(Relocation& pReloc,
                      IRBuilder& pBuilder,
                      Module& pModule,
                      LDSection& pSection,
                      Input& pInput);

private:
  NyuziGNULDBackend& m_Target;
  RelRelMap m_RelRelMap;
};

} // namespace of mcld

#endif

