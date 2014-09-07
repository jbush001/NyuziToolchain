//===- VectorProcRelocator.cpp  ----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include <mcld/LinkerConfig.h>
#include <mcld/IRBuilder.h>
#include <mcld/Support/MsgHandling.h>
#include <mcld/LD/LDSymbol.h>
#include <mcld/LD/ELFFileFormat.h>
#include <mcld/Object/ObjectBuilder.h>

#include <llvm/ADT/Twine.h>
#include <llvm/Support/DataTypes.h>
#include <llvm/Support/ELF.h>
#include <llvm/Support/Host.h>

#include "VectorProcRelocator.h"
#include "VectorProcRelocationFunctions.h"
#include "VectorProcRelocationHelpers.h"

using namespace mcld;

//===----------------------------------------------------------------------===//
// Relocation Functions and Tables
//===----------------------------------------------------------------------===//
DECL_VECTORPROC_APPLY_RELOC_FUNCS

/// the prototype of applying function
typedef Relocator::Result (*ApplyFunctionType)(Relocation& pReloc,
                                               VectorProcRelocator& pParent);

// the table entry of applying functions
class ApplyFunctionEntry {
public:
  ApplyFunctionEntry() {}
  ApplyFunctionEntry(ApplyFunctionType pFunc,
                     const char* pName,
                     size_t pSize = 0)
      : func(pFunc), name(pName), size(pSize) { }
  ApplyFunctionType func;
  const char* name;
  size_t size;
};
typedef std::map<Relocator::Type, ApplyFunctionEntry> ApplyFunctionMap;

static const ApplyFunctionMap::value_type ApplyFunctionList[] = {
  DECL_VECTORPROC_APPLY_RELOC_FUNC_PTRS(ApplyFunctionMap::value_type,
                                     ApplyFunctionEntry)
};

// declare the table of applying functions
static ApplyFunctionMap ApplyFunctions(ApplyFunctionList,
    ApplyFunctionList + sizeof(ApplyFunctionList)/sizeof(ApplyFunctionList[0]));

//===----------------------------------------------------------------------===//
// VectorProcRelocator
//===----------------------------------------------------------------------===//
VectorProcRelocator::VectorProcRelocator(VectorProcGNULDBackend& pParent,
                                   const LinkerConfig& pConfig)
  : Relocator(pConfig),
    m_Target(pParent) {
}

VectorProcRelocator::~VectorProcRelocator()
{
}

Relocator::Result VectorProcRelocator::applyRelocation(Relocation& pRelocation)
{
  Relocation::Type type = pRelocation.type();
  assert(ApplyFunctions.find(type) != ApplyFunctions.end());
  return ApplyFunctions[type].func(pRelocation, *this);
}

const char* VectorProcRelocator::getName(Relocator::Type pType) const
{
  assert(ApplyFunctions.find(pType) != ApplyFunctions.end());
  return ApplyFunctions[pType].name;
}

Relocator::Size VectorProcRelocator::getSize(Relocation::Type pType) const
{
  return ApplyFunctions[pType].size;
}

void VectorProcRelocator::scanRelocation(Relocation& pReloc,
                                      IRBuilder& pBuilder,
                                      Module& pModule,
                                      LDSection& pSection,
                                      Input& pInput)
{
  ResolveInfo* rsym = pReloc.symInfo();
  assert(NULL != rsym &&
         "ResolveInfo of relocation not set while scanRelocation");

  assert(NULL != pSection.getLink());
  if (0 == (pSection.getLink()->flag() & llvm::ELF::SHF_ALLOC))
    return;

  // check if we shoule issue undefined reference for the relocation target
  // symbol
  if (rsym->isUndef() && !rsym->isDyn() && !rsym->isWeak() && !rsym->isNull())
    issueUndefRef(pReloc, pSection, pInput);
}

//===----------------------------------------------------------------------===//
// Each relocation function implementation
//===----------------------------------------------------------------------===//

Relocator::Result unsupport(Relocation& pReloc, VectorProcRelocator& pParent)
{
  return Relocator::Unsupport;
}

Relocator::Result abs(Relocation& pReloc, VectorProcRelocator& pParent)
{
  Relocator::DWord A = pReloc.target() + pReloc.addend();
  Relocator::DWord S = pReloc.symValue();

  pReloc.target() = S + A;
  return Relocator::OK;
}

Relocator::Result branch(Relocation& pReloc, VectorProcRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::DWord   A = pReloc.addend();

  pReloc.target() = helper_replace_field(pReloc.target(), S + A, 5, 20);

  return Relocator::OK;
}

Relocator::Result mem(Relocation& pReloc, VectorProcRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::DWord   A = pReloc.addend();

  pReloc.target() = helper_replace_field(pReloc.target(), S + A, 15, 10);

  return Relocator::OK;
}

Relocator::Result memext(Relocation& pReloc, VectorProcRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::DWord   A = pReloc.addend();

  pReloc.target() = helper_replace_field(pReloc.target(), S + A, 10, 15);

  return Relocator::OK;
}


