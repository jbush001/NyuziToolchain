//===- lib/ReaderWriter/ELF/VectorProc/VectorProcTargetHandler.cpp ----------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "VectorProcTargetHandler.h"
#include "VectorProcTargetInfo.h"
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
               (uint32_t)*reinterpret_cast<llvm::support::ulittle32_t *>(location)
               | (offset << 5);
    return 0;
  }
  return 1;
}

int relocABS32(uint8_t *location, uint64_t relocAddr, uint64_t target, uint64_t addend) {
    *reinterpret_cast<llvm::support::ulittle32_t *>(location) = target;
    return 0;
}

} // end anon namespace

ErrorOr<void> VectorProcTargetRelocationHandler::applyRelocation(
    ELFWriter &writer, llvm::FileOutputBuffer &buf, const lld::AtomLayout &atom,
    const Reference &ref) const {
  uint8_t *atomContent = buf.getBufferStart() + atom._fileOffset;
  uint8_t *location = atomContent + ref.offsetInAtom();
  uint64_t targetVAddress = writer.addressOfAtom(ref.target());
  uint64_t relocVAddress = atom._virtualAddr + ref.offsetInAtom();

  switch (ref.kind()) {
  case R_VECTORPROC_BRANCH:
    relocBRANCH(location, relocVAddress, targetVAddress, ref.addend());
    break;

  case R_VECTORPROC_ABS32:
    relocABS32(location, relocVAddress, targetVAddress, ref.addend());
    break;

  case lld::Reference::kindLayoutAfter:
  case lld::Reference::kindLayoutBefore:
  case lld::Reference::kindInGroup:
    break;

  default : {
    std::string str;
    llvm::raw_string_ostream s(str);
    auto name = _targetInfo.stringFromRelocKind(ref.kind());
    s << "Unhandled relocation: "
      << (name ? *name : "<unknown>" ) << " (" << ref.kind() << ")";
    s.flush();
    llvm_unreachable(str.c_str());
  }
  }

  return error_code::success();
}

VectorProcTargetHandler::VectorProcTargetHandler(VectorProcTargetInfo &targetInfo)
    : DefaultTargetHandler(targetInfo), _relocationHandler(targetInfo),
      _targetLayout(targetInfo) {
}
