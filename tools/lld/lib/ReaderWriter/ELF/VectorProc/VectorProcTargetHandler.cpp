//===- lib/ReaderWriter/ELF/VectorProc/VectorProcTargetHandler.cpp ----------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "VectorProcTargetHandler.h"
#include "VectorProcLinkingContext.h"
#include "llvm/Support/Debug.h"

using namespace lld;
using namespace elf;

using namespace llvm::ELF;

namespace {
int relocBRANCH(uint8_t *location, uint64_t relocAddr, uint64_t target, uint64_t addend) {
  int32_t offset = (uint32_t)(((target + addend) - (relocAddr + 4)));
  if ((offset < 0x7ffff) && (offset > -0x7ffff)) {
    offset &= 0xfffff;
    *reinterpret_cast<llvm::support::ulittle32_t *>(location) = 
               ((uint32_t)*reinterpret_cast<llvm::support::ulittle32_t *>(location)
               & ~(0xfffff << 5)) | (offset << 5);
    return 0;
  }
  return 1;
}

int relocABS32(uint8_t *location, uint64_t relocAddr, uint64_t target, uint64_t addend) {
    *reinterpret_cast<llvm::support::ulittle32_t *>(location) = target + addend;
    return 0;
}

} // end anon namespace

std::error_code VectorProcTargetRelocationHandler::applyRelocation(
    ELFWriter &writer, llvm::FileOutputBuffer &buf, const lld::AtomLayout &atom,
    const Reference &ref) const {
  uint8_t *atomContent = buf.getBufferStart() + atom._fileOffset;
  uint8_t *location = atomContent + ref.offsetInAtom();
  uint64_t targetVAddress = writer.addressOfAtom(ref.target());
  uint64_t relocVAddress = atom._virtualAddr + ref.offsetInAtom();

  if (ref.kindNamespace() != Reference::KindNamespace::ELF)
    return std::error_code();

  switch (ref.kindValue()) {
  case R_VECTORPROC_BRANCH:
    relocBRANCH(location, relocVAddress, targetVAddress, ref.addend());
    break;

  case R_VECTORPROC_ABS32:
    relocABS32(location, relocVAddress, targetVAddress, ref.addend());
    break;

  default : {
    std::string str;
    llvm::raw_string_ostream s(str);
    s << "Unhandled relocation #" << ref.kindValue();
    s.flush();
    llvm_unreachable(str.c_str());
  }
  }

  return std::error_code();
}

VectorProcTargetHandler::VectorProcTargetHandler(VectorProcLinkingContext &context)
    : DefaultTargetHandler(context), _relocationHandler(context),
      _targetLayout(context), _linkingContext(context) {
}

void VectorProcTargetHandler::registerRelocationNames(Registry &registry) {
  registry.addKindTable(Reference::KindNamespace::ELF,
                        Reference::KindArch::VectorProc, kindStrings);
}

std::unique_ptr<Writer> VectorProcTargetHandler::getWriter() {
  switch (_linkingContext.getOutputELFType()) {
  case llvm::ELF::ET_EXEC:
    return std::unique_ptr<Writer>(new elf::ExecutableWriter<VectorProcELFType>(
        _linkingContext, _targetLayout));
  default:
    llvm_unreachable("unsupported output type");
  }
}

const Registry::KindStrings VectorProcTargetHandler::kindStrings[] = {
  LLD_KIND_STRING_ENTRY(R_VECTORPROC_BRANCH),
  LLD_KIND_STRING_ENTRY(R_VECTORPROC_ABS32),
  LLD_KIND_STRING_END
};

