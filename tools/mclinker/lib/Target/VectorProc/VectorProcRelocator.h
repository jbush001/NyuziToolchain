//===-  VectorProcRelocator.h ------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_VECTORPROC_VECTORPROCRELOCATOR_H
#define TARGET_VECTORPROC_VECTORPROCRELOCATOR_H

#include <mcld/LD/Relocator.h>
#include <mcld/Target/GOT.h>
#include <mcld/Target/KeyEntryMap.h>
#include "VectorProcLDBackend.h"

namespace mcld {

/** \class VectorProcRelocator
 *  \brief VectorProcRelocator creates and destroys the VectorProc relocations.
 *
 */
class VectorProcRelocator : public Relocator
{
public:
  typedef KeyEntryMap<Relocation, Relocation> RelRelMap;


public:
  VectorProcRelocator(VectorProcGNULDBackend& pParent, const LinkerConfig& pConfig);
  ~VectorProcRelocator();

  Result applyRelocation(Relocation& pRelocation);

  VectorProcGNULDBackend& getTarget()
  { return m_Target; }

  const VectorProcGNULDBackend& getTarget() const
  { return m_Target; }

  const char* getName(Relocation::Type pType) const;

  Size getSize(Relocation::Type pType) const;

  const RelRelMap& getRelRelMap() const { return m_RelRelMap; }
  RelRelMap&       getRelRelMap()       { return m_RelRelMap; }

  /// scanRelocation - determine the empty entries are needed or not and create
  /// the empty entries if needed.
  /// For VectorProc, following entries are check to create:
  /// - GOT entry (for .got section)
  /// - PLT entry (for .plt section)
  /// - dynamin relocation entries (for .rel.plt and .rel.dyn sections)
  void scanRelocation(Relocation& pReloc,
                      IRBuilder& pBuilder,
                      Module& pModule,
                      LDSection& pSection,
                      Input& pInput);

private:

private:
  VectorProcGNULDBackend& m_Target;
  RelRelMap m_RelRelMap;
};

} // namespace of mcld

#endif

