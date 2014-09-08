//===- VectorProcRelocationFunction.h ----------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#define DECL_VECTORPROC_APPLY_RELOC_FUNC(Name) \
static VectorProcRelocator::Result Name (Relocation& pEntry, VectorProcRelocator& pParent);

#define DECL_VECTORPROC_APPLY_RELOC_FUNCS \
DECL_VECTORPROC_APPLY_RELOC_FUNC(none) \
DECL_VECTORPROC_APPLY_RELOC_FUNC(abs) \
DECL_VECTORPROC_APPLY_RELOC_FUNC(branch) \
DECL_VECTORPROC_APPLY_RELOC_FUNC(mem) \
DECL_VECTORPROC_APPLY_RELOC_FUNC(memext)

#define DECL_VECTORPROC_APPLY_RELOC_FUNC_PTRS(ValueType, MappedType) \
  ValueType(0x0, MappedType(&none, "R_VECTORPROC_NONE")), \
  ValueType(0x1, MappedType(&abs, "R_VECTORPROC_ABS32", 32)), \
  ValueType(0x2, MappedType(&branch, "R_VECTORPROC_BRANCH", 32)), \
  ValueType(0x3, MappedType(&mem, "R_VECTORPROC_PCREL_MEM", 32)), \
  ValueType(0x4, MappedType(&memext, "R_VECTORPROC_PCREL_MEM_EXT", 32))

