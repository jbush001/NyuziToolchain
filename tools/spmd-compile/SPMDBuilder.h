#ifndef __SPMD_BUILDER_H
#define __SPMD_BUILDER_H

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"

class SPMDBuilder {
public:
  SPMDBuilder(llvm::Module *Mod);
  ~SPMDBuilder();
	void startFunction(const char *name, const std::vector<std::string> &ArgNames);
  void endFunction();
  llvm::Function::arg_iterator getFuncArguments();
  
  void createReturn(llvm::Value *ReturnValue);
  
  llvm::Value *createLocalVariable(const char *Name);

  llvm::Value *readLocalVariable(llvm::Value*);
  
  /// Copy the value of the expression NewValue into the given variable (an alloca),
  /// Applying a mask if one is active.
  void assignLocalVariable(llvm::Value *Variable, llvm::Value *NewValue);

  /// Save the current mask (if present), and it with the new mask, then cause the 
  /// new one to affect all subsequent emitted instructions
  void pushMask(llvm::Value *mask);

  /// Revert to the previous mask before pushMask (possibly having no mask if there 
  /// wasn't one prior to that)
  void popMask();

  /// This is basically for the else clause of if statements
  void invertLastPushedMask();
  
  /// Emit a branch to skip the block if no mask bits are set.
  void shortCircuitZeroMask(llvm::BasicBlock *SkipTo, llvm::BasicBlock *Next);
  
  void branch(llvm::BasicBlock *Dest);
  
  llvm::Value *createCompare(llvm::CmpInst::Predicate type, llvm::Value *lhs, llvm::Value *rhs);

  llvm::Value *createSub(llvm::Value *lhs, llvm::Value *rhs);
  llvm::Value *createAdd(llvm::Value *lhs, llvm::Value *rhs);
  llvm::Value *createMul(llvm::Value *lhs, llvm::Value *rhs);
  llvm::Value *createDiv(llvm::Value *lhs, llvm::Value *rhs);

  llvm::BasicBlock *createBasicBlock(const char *Name);
  
  void setInsertPoint(llvm::BasicBlock *Block);
  
  llvm::Value *createConstant(float value);

private:
  struct MaskStackEntry {
    // These entries point to the allocas that store the values.
    llvm::Value *ThisMask;
    llvm::Value *CombinedValue;
  };

  // Returns pointer to alloca that contains value
  llvm::Value *getCurrentMask();

  llvm::IRBuilder<> Builder;
  llvm::Module *MainModule;
  llvm::SmallVector<MaskStackEntry, 10> MaskStack;
  llvm::Function *CurrentFunction;
};

#endif
