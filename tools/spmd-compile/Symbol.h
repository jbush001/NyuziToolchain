#ifndef __SYMBOL_H
#define __SYMBOL_H

#include "llvm/IR/IRBuilder.h"
#include <string>

struct Symbol {
  llvm::Value *Val;
  std::string Name;
};

#endif
