//===- NyuziRelocator.cpp  ----------------------------------------------===//
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
#include <mcld/Support/raw_ostream.h>

#include "NyuziRelocator.h"
#include "NyuziRelocationFunctions.h"
#include "NyuziRelocationHelpers.h"

using namespace mcld;

//===----------------------------------------------------------------------===//
// Relocation Functions and Tables
//===----------------------------------------------------------------------===//
DECL_NYUZI_APPLY_RELOC_FUNCS

/// the prototype of applying function
typedef Relocator::Result (*ApplyFunctionType)(Relocation& pReloc,
                                               NyuziRelocator& pParent);

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
  DECL_NYUZI_APPLY_RELOC_FUNC_PTRS(ApplyFunctionMap::value_type,
                                     ApplyFunctionEntry)
};

// declare the table of applying functions
static ApplyFunctionMap ApplyFunctions(ApplyFunctionList,
    ApplyFunctionList + sizeof(ApplyFunctionList)/sizeof(ApplyFunctionList[0]));

//===----------------------------------------------------------------------===//
// NyuziRelocator
//===----------------------------------------------------------------------===//
NyuziRelocator::NyuziRelocator(NyuziGNULDBackend& pParent,
                                   const LinkerConfig& pConfig)
  : Relocator(pConfig),
    m_Target(pParent) {
}

NyuziRelocator::~NyuziRelocator()
{
}

Relocator::Result NyuziRelocator::applyRelocation(Relocation& pRelocation)
{
  Relocation::Type type = pRelocation.type();
  assert(ApplyFunctions.find(type) != ApplyFunctions.end());
  return ApplyFunctions[type].func(pRelocation, *this);
}

uint32_t NyuziRelocator::getDebugStringOffset(Relocation& pReloc) const {
  if (pReloc.type() != llvm::ELF::R_NYUZI_ABS32)
    error(diag::unsupport_reloc_for_debug_string) << getName(pReloc.type());

  return pReloc.symInfo()->outSymbol()->fragRef()->offset() +
         pReloc.target() + pReloc.addend();
}

void NyuziRelocator::applyDebugStringOffset(Relocation& pReloc,
                                            uint32_t pOffset) {
  pReloc.target() = pOffset;
}

const char* NyuziRelocator::getName(Relocator::Type pType) const
{
  assert(ApplyFunctions.find(pType) != ApplyFunctions.end());
  return ApplyFunctions[pType].name;
}

Relocator::Size NyuziRelocator::getSize(Relocation::Type pType) const
{
  return ApplyFunctions[pType].size;
}

void NyuziRelocator::scanRelocation(Relocation& pReloc,
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

Relocator::Result none(Relocation& pReloc, NyuziRelocator& pParent)
{
  return Relocator::OK;
}


Relocator::Result abs(Relocation& pReloc, NyuziRelocator& pParent)
{
  Relocator::DWord A = pReloc.addend();
  Relocator::DWord S = pReloc.symValue();
  pReloc.target() = S + A;

  return Relocator::OK;
}

Relocator::Result branch(Relocation& pReloc, NyuziRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::Address P = pReloc.place();
  int offset = S - (P + 4);

  if (helper_check_signed_overflow(offset, 20))
    return Relocator::Overflow;

  pReloc.target() = helper_replace_field(pReloc.target(), offset, 5, 20);

  return Relocator::OK;
}

Relocator::Result mem(Relocation& pReloc, NyuziRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::Address P = pReloc.place();
  int offset = S - (P + 4);

  if (helper_check_signed_overflow(offset, 10))
    return Relocator::Overflow;

  pReloc.target() = helper_replace_field(pReloc.target(), offset, 15, 10);

  return Relocator::OK;
}

Relocator::Result memext(Relocation& pReloc, NyuziRelocator& pParent)
{
  Relocator::Address S = pReloc.symValue();
  Relocator::Address P = pReloc.place();
  Relocator::Address A = pReloc.addend();
  int offset = (S + A) - (P + 4);

  if (helper_check_signed_overflow(offset, 15))
    return Relocator::Overflow;

  pReloc.target() = helper_replace_field(pReloc.target(), offset, 10, 15);

  return Relocator::OK;
}


