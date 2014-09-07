//===- VectorProc.h ----------------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_VECTORPROC_VECTORPROC_H
#define TARGET_VECTORPROC_VECTORPROC_H
#include <string>

namespace llvm {
class Target;
} // namespace of llvm

namespace mcld {

class Target;
class TargetLDBackend;

extern mcld::Target TheVectorProcTarget;

TargetLDBackend *createVectorProcLDBackend(const llvm::Target&,
                                        const std::string&);

} // namespace of mcld

#endif

