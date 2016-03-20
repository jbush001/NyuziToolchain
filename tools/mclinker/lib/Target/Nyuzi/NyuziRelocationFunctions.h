//===- NyuziRelocationFunction.h ----------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#define DECL_NYUZI_APPLY_RELOC_FUNC(Name)                \
  static NyuziRelocator::Result Name(Relocation& pEntry, \
                                     NyuziRelocator& pParent);

#define DECL_NYUZI_APPLY_RELOC_FUNCS  \
  DECL_NYUZI_APPLY_RELOC_FUNC(none)   \
  DECL_NYUZI_APPLY_RELOC_FUNC(abs)    \
  DECL_NYUZI_APPLY_RELOC_FUNC(branch) \
  DECL_NYUZI_APPLY_RELOC_FUNC(mem)    \
  DECL_NYUZI_APPLY_RELOC_FUNC(memext) \
  DECL_NYUZI_APPLY_RELOC_FUNC(lea)

#define DECL_NYUZI_APPLY_RELOC_FUNC_PTRS(ValueType, MappedType)         \
  ValueType(0x0, MappedType(&none, "R_NYUZI_NONE")),                    \
      ValueType(0x1, MappedType(&abs, "R_NYUZI_ABS32", 32)),            \
      ValueType(0x2, MappedType(&branch, "R_NYUZI_BRANCH", 32)),        \
      ValueType(0x3, MappedType(&mem, "R_NYUZI_PCREL_MEM", 32)),        \
      ValueType(0x4, MappedType(&memext, "R_NYUZI_PCREL_MEM_EXT", 32)), \
      ValueType(0x5, MappedType(&lea, "R_NYUZI_PCREL_LEA", 32))
