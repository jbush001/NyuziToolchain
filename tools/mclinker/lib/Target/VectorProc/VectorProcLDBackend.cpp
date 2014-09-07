//===- VectorProcLDBackend.cpp -----------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "VectorProc.h"
#include "VectorProcELFDynamic.h"
#include "VectorProcGNUInfo.h"
#include "VectorProcLDBackend.h"
#include "VectorProcRelocator.h"

#include <cstring>

#include <llvm/ADT/Triple.h>
#include <llvm/ADT/Twine.h>
#include <llvm/Support/ELF.h>
#include <llvm/Support/Casting.h>

#include <mcld/IRBuilder.h>
#include <mcld/LinkerConfig.h>
#include <mcld/Fragment/FillFragment.h>
#include <mcld/Fragment/AlignFragment.h>
#include <mcld/Fragment/RegionFragment.h>
#include <mcld/Fragment/Stub.h>
#include <mcld/Fragment/NullFragment.h>
#include <mcld/Support/MemoryRegion.h>
#include <mcld/Support/MemoryArea.h>
#include <mcld/Support/MsgHandling.h>
#include <mcld/Support/TargetRegistry.h>
#include <mcld/LD/BranchIslandFactory.h>
#include <mcld/LD/StubFactory.h>
#include <mcld/LD/LDContext.h>
#include <mcld/LD/ELFFileFormat.h>
#include <mcld/LD/ELFSegmentFactory.h>
#include <mcld/LD/ELFSegment.h>
#include <mcld/Target/ELFAttribute.h>
#include <mcld/Target/GNUInfo.h>
#include <mcld/Object/ObjectBuilder.h>

using namespace mcld;

//===----------------------------------------------------------------------===//
// VectorProcGNULDBackend
//===----------------------------------------------------------------------===//
VectorProcGNULDBackend::VectorProcGNULDBackend(const LinkerConfig& pConfig,
                                         GNUInfo* pInfo)
  : GNULDBackend(pConfig, pInfo),
    m_pRelocator(NULL),
    m_pRelaDyn(NULL),
    m_pDynamic(NULL)
{
}

VectorProcGNULDBackend::~VectorProcGNULDBackend()
{
  if (m_pRelocator != NULL)
    delete m_pRelocator;
  if (m_pRelaDyn != NULL)
    delete m_pRelaDyn;
  if (m_pDynamic != NULL)
    delete m_pDynamic;
}

void VectorProcGNULDBackend::initTargetSections(Module& pModule,
                                             ObjectBuilder& pBuilder)
{
  // TODO

  if (LinkerConfig::Object != config().codeGenType()) {
    ELFFileFormat* file_format = getOutputFormat();

    // initialize .rela.dyn
    LDSection& reladyn = file_format->getRelaDyn();
    m_pRelaDyn = new OutputRelocSection(pModule, reladyn);
  }
}

void VectorProcGNULDBackend::initTargetSymbols(IRBuilder& pBuilder,
                                            Module& pModule)
{
}

bool VectorProcGNULDBackend::initRelocator()
{
  if (NULL == m_pRelocator) {
    m_pRelocator = new VectorProcRelocator(*this, config());
  }
  return true;
}

const Relocator* VectorProcGNULDBackend::getRelocator() const
{
  assert(NULL != m_pRelocator);
  return m_pRelocator;
}

Relocator* VectorProcGNULDBackend::getRelocator()
{
  assert(NULL != m_pRelocator);
  return m_pRelocator;
}

void VectorProcGNULDBackend::doPreLayout(IRBuilder& pBuilder)
{
  // initialize .dynamic data
  if (!config().isCodeStatic() && NULL == m_pDynamic)
    m_pDynamic = new VectorProcELFDynamic(*this, config());

  if (LinkerConfig::Object != config().codeGenType()) {
    ELFFileFormat* file_format = getOutputFormat();
    // set .rela.dyn size
    if (!m_pRelaDyn->empty()) {
      assert(!config().isCodeStatic() &&
            "static linkage should not result in a dynamic relocation section");
      file_format->getRelaDyn().setSize(
                                m_pRelaDyn->numOfRelocs() * getRelaEntrySize());
    }
  }
}

void VectorProcGNULDBackend::doPostLayout(Module& pModule, IRBuilder& pBuilder)
{
}

VectorProcELFDynamic& VectorProcGNULDBackend::dynamic()
{
  assert(NULL != m_pDynamic);
  return *m_pDynamic;
}

const VectorProcELFDynamic& VectorProcGNULDBackend::dynamic() const
{
  assert(NULL != m_pDynamic);
  return *m_pDynamic;
}

uint64_t VectorProcGNULDBackend::emitSectionData(const LDSection& pSection,
                                              MemoryRegion& pRegion) const
{
  assert(pRegion.size() && "Size of MemoryRegion is zero!");

  return pRegion.size();
}

unsigned int
VectorProcGNULDBackend::getTargetSectionOrder(const LDSection& pSectHdr) const
{
  const ELFFileFormat* file_format = getOutputFormat();

  return SHO_UNDEFINED;
}

bool VectorProcGNULDBackend::doRelax(Module& pModule,
                                  IRBuilder& pBuilder,
                                  bool& pFinished)
{
  // TODO
  return false;
}

bool VectorProcGNULDBackend::initTargetStubs()
{
  // TODO
  return true;
}

void VectorProcGNULDBackend::doCreateProgramHdrs(Module& pModule)
{
  // TODO
}

bool VectorProcGNULDBackend::finalizeTargetSymbols()
{
  // TODO
  return true;
}

bool VectorProcGNULDBackend::mergeSection(Module& pModule,
                                       const Input& pInput,
                                       LDSection& pSection)
{
  // TODO
  return true;
}

bool VectorProcGNULDBackend::readSection(Input& pInput, SectionData& pSD)
{
  // TODO
  return true;
}

OutputRelocSection& VectorProcGNULDBackend::getRelaDyn()
{
  assert(NULL != m_pRelaDyn && ".rela.dyn section not exist");
  return *m_pRelaDyn;
}

const OutputRelocSection& VectorProcGNULDBackend::getRelaDyn() const
{
  assert(NULL != m_pRelaDyn && ".rela.dyn section not exist");
  return *m_pRelaDyn;
}

namespace mcld {

//===----------------------------------------------------------------------===//
//  createVectorProcLDBackend - the help funtion to create corresponding
//  VectorProcLDBackend
//===----------------------------------------------------------------------===//
TargetLDBackend* createVectorProcLDBackend(const LinkerConfig& pConfig)
{
  if (pConfig.targets().triple().isOSDarwin()) {
    assert(0 && "MachO linker is not supported");
  }
  if (pConfig.targets().triple().isOSWindows()) {
    assert(0 && "COFF linker is not supported");
  }
  return new VectorProcGNULDBackend(pConfig,
     new VectorProcGNUInfo(pConfig.targets().triple()));
}

} // namespace of mcld

//===----------------------------------------------------------------------===//
// Force static initialization.
//===----------------------------------------------------------------------===//
extern "C" void MCLDInitializeVectorProcLDBackend() {
  // Register the linker backend
  mcld::TargetRegistry::RegisterTargetLDBackend(TheVectorProcTarget,
                                                createVectorProcLDBackend);
}

