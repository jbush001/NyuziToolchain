//===- Nyuzi.h ----------------------------------------------------------===//
//
//                     The MCLinker Project
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef TARGET_NYUZI_NYUZI_H
#define TARGET_NYUZI_NYUZI_H
#include <string>

namespace llvm {
class Target;
}  // namespace of llvm

namespace mcld {

class Target;
class TargetLDBackend;

extern mcld::Target TheNyuziTarget;

TargetLDBackend *createNyuziLDBackend(const llvm::Target &,
                                      const std::string &);

}  // namespace of mcld

#endif
