#include "SPMDBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

SPMDBuilder::SPMDBuilder(Module *Mod, LLVMContext &_Context)
    : Context(_Context), Builder(_Context), MainModule(Mod), CurrentFunction(nullptr) {
  sFloatType = Type::getFloatTy(Context);
  sMaskType = VectorType::get(Type::getInt1Ty(Context), 16);
  sMaskIntType = Type::getInt16Ty(Context);
}

SPMDBuilder::~SPMDBuilder() {}

void SPMDBuilder::startFunction(const char *Name,
                                const std::vector<std::string> &ArgNames) {
  Type *VecF = VectorType::get(sFloatType, 16);
  std::vector<Type *> Params(ArgNames.size(), VecF);
  FunctionType *FT = FunctionType::get(VecF, Params, false);
  CurrentFunction = Function::Create(FT, Function::ExternalLinkage, Name,
    MainModule);

  BasicBlock *EntryBB = BasicBlock::Create(Context, "entry",
    CurrentFunction);
  startBasicBlock(EntryBB);

  unsigned Idx = 0;
  for (Function::arg_iterator AI = CurrentFunction->arg_begin();
       Idx != ArgNames.size(); ++AI, ++Idx) {
    AI->setName(ArgNames[Idx]);
  }

  ReturnValuePtr = createLocalVariable("return_value", sFloatType);

  // ReturnMask indicates which lanes have returned values. Each bit is
  // 1 if the lane is still active (hasn't returned) and 0 if it has returned.
  ReturnMaskPtr = Builder.CreateAlloca(sMaskType, nullptr, "return_mask");
  Builder.CreateStore(
      ConstantVector::getSplat(16, ConstantInt::getTrue(Context)),
      ReturnMaskPtr);

  ActiveLanes = nullptr;
}

void SPMDBuilder::endFunction() {
  assert(MaskStack.empty());

  // XXX this is either redundant, or creates an implicit return value.
  // Probably not the right thing to do.
//  Builder.CreateRet(readLocalVariable(ReturnValuePtr));
}

llvm::Function::arg_iterator SPMDBuilder::getFuncArguments() {
  return CurrentFunction->arg_begin();
}

void SPMDBuilder::createReturn(llvm::Value *ReturnValue) {
  assignLocalVariable(ReturnValuePtr, ReturnValue);
  if (MaskStack.empty()) {
    // All lanes are returning because this isn't predicated.
    // Jump directly to end
    Builder.CreateRet(readLocalVariable(ReturnValuePtr));
  } else {
    assert(ActiveLanes);

    // Some lanes are returning and some are not. Update ReturnMask
    // to indicate which lanes have returned.
    Value *OldReturnMask = Builder.CreateLoad(ReturnMaskPtr);
    Value *InactiveLanes = Builder.CreateNot(ActiveLanes);
    Value *NewReturnMask = Builder.CreateAnd(OldReturnMask, InactiveLanes);

    // If all of the lanes have returned, jump to the exit.
    llvm::Value *ExitCond = Builder.CreateICmpEQ(
        Builder.CreateBitCast(NewReturnMask, sMaskIntType),
        ConstantInt::get(sMaskType, 0));

    llvm::BasicBlock *NextBlock = createBasicBlock("noreturnyet");
    llvm::BasicBlock *ReturnBlock = createBasicBlock("doreturn");
    Builder.CreateCondBr(ExitCond, ReturnBlock, NextBlock);
    startBasicBlock(ReturnBlock);
    Builder.CreateRet(readLocalVariable(ReturnValuePtr));

    // All lanes haven't exited yet
    startBasicBlock(NextBlock);
    Builder.CreateStore(NewReturnMask, ReturnMaskPtr);

    // Update current execution mask
    MaskStackEntry &Top = MaskStack.back();
    ActiveLanes = Builder.CreateAnd(Top.CombinedMask, NewReturnMask);
    Top.CombinedMask = ActiveLanes;
  }
}

llvm::Value *SPMDBuilder::createLocalVariable(const char *Name, Type *Type) {
  return Builder.CreateAlloca(VectorType::get(Type, 16), 0, Name);
}

llvm::Value *SPMDBuilder::readLocalVariable(llvm::Value *VariablePtr) {
  return Builder.CreateLoad(VariablePtr);
}

llvm::Value *SPMDBuilder::assignLocalVariable(Value *VariablePtr,
                                              Value *NewValue) {
  assert(VariablePtr);
  assert(NewValue);

  if (ActiveLanes) {
    // Need to predicate this instruction
    Value *OldValue = Builder.CreateLoad(VariablePtr);
    Value *Blended = Builder.CreateSelect(ActiveLanes, NewValue, OldValue);
    Builder.CreateStore(Blended, VariablePtr);
  } else {
    assert(MaskStack.empty());
    Builder.CreateStore(NewValue, VariablePtr);
  }

  return NewValue;
}

void SPMDBuilder::pushMask(Value *MaskValue) {
  if (ActiveLanes) {
    Value *NewCombinedMask =
        Builder.CreateAnd(MaskValue, ActiveLanes, "pred");
    MaskStackEntry Entry = {MaskValue, NewCombinedMask};
    MaskStack.push_back(Entry);
    ActiveLanes = NewCombinedMask;
  } else {
    assert(MaskStack.empty());
    MaskStackEntry Entry = {MaskValue, MaskValue};
    MaskStack.push_back(Entry);
    ActiveLanes = MaskValue;
  }
}

void SPMDBuilder::popMask() {
  assert(ActiveLanes);
  assert(!MaskStack.empty());

  // Pop off current mask entry
  MaskStack.pop_back();

  Value *ReturnMask = Builder.CreateLoad(ReturnMaskPtr);
  if (MaskStack.empty()) {
    // Popped last entry off stack, no longer in conditional code.
    ActiveLanes = ReturnMask;
  } else {
    // If there was an old entry, it needs to be combined with return
    // mask.
    MaskStackEntry &Top = MaskStack.back();
    ActiveLanes = Builder.CreateAnd(Top.CombinedMask, ReturnMask);
    Top.CombinedMask = ActiveLanes;
  }
}

void SPMDBuilder::invertLastPushedMask() {
  assert(!MaskStack.empty());
  assert(ActiveLanes);

  MaskStackEntry PreviousTop = MaskStack.back();
  MaskStack.pop_back();

  Value *NewMask = Builder.CreateNot(PreviousTop.ThisMask, "invpred");
  Value *NewCombined;
  if (MaskStack.empty())
    NewCombined = NewMask;
  else
    NewCombined = Builder.CreateAnd(NewMask, MaskStack.back().CombinedMask);

  // Combine with return mask
  Value *ReturnMaskValue = Builder.CreateLoad(ReturnMaskPtr);
  ActiveLanes = Builder.CreateAnd(NewCombined, ReturnMaskValue);

  MaskStackEntry NewTop = {NewMask, ActiveLanes};
  MaskStack.push_back(NewTop);
}

void SPMDBuilder::shortCircuitZeroMask(llvm::BasicBlock *SkipTo,
                                       llvm::BasicBlock *Next) {
  assert(!MaskStack.empty());
  assert(ActiveLanes);

  llvm::Value *BoolCond = Builder.CreateICmpEQ(
      Builder.CreateBitCast(ActiveLanes, sMaskIntType),
      ConstantInt::get(sMaskIntType, 0));
  Builder.CreateCondBr(BoolCond, SkipTo, Next);
}

void SPMDBuilder::branch(llvm::BasicBlock *Dest) { Builder.CreateBr(Dest); }

Value *SPMDBuilder::createCompare(CmpInst::Predicate Type, Value *lhs,
                                  Value *rhs) {

  switch (Type) {
  case CmpInst::FCMP_OEQ:
  case CmpInst::FCMP_UEQ:
    return Builder.CreateFCmpUEQ(lhs, rhs);

  case CmpInst::FCMP_ONE:
  case CmpInst::FCMP_UNE:
  return Builder.CreateFCmpUNE(lhs, rhs);

  case CmpInst::FCMP_OGT:
  case CmpInst::FCMP_UGT:
  return Builder.CreateFCmpUGT(lhs, rhs);

  case CmpInst::FCMP_OGE:
  case CmpInst::FCMP_UGE:
  return Builder.CreateFCmpUGE(lhs, rhs);

  case CmpInst::FCMP_OLT:
  case CmpInst::FCMP_ULT:
  return Builder.CreateFCmpULT(lhs, rhs);

  case CmpInst::FCMP_OLE:
  case CmpInst::FCMP_ULE:
  return Builder.CreateFCmpULE(lhs, rhs);

  default:
    llvm_unreachable("Unknown comparision type");
  }
}

Value *SPMDBuilder::createSub(Value *Lhs, Value *Rhs) {
  return Builder.CreateFSub(Lhs, Rhs);
}

Value *SPMDBuilder::createAdd(Value *Lhs, Value *Rhs) {
  return Builder.CreateFAdd(Lhs, Rhs);
}

Value *SPMDBuilder::createMul(Value *Lhs, Value *Rhs) {
  return Builder.CreateFMul(Lhs, Rhs);
}

Value *SPMDBuilder::createDiv(Value *Lhs, Value *Rhs) {
  return Builder.CreateFDiv(Lhs, Rhs);
}

BasicBlock *SPMDBuilder::createBasicBlock(const char *name) {
  return BasicBlock::Create(Context, name, CurrentFunction);
}

void SPMDBuilder::startBasicBlock(BasicBlock *BB) {
  // Add a branch at the end of the last block if needed
  if (Builder.GetInsertBlock() && !Builder.GetInsertBlock()->empty()
    && !std::prev(Builder.GetInsertPoint())->isTerminator())
    Builder.CreateBr(BB);

  Builder.SetInsertPoint(BB);
}

Value *SPMDBuilder::createConstant(float Value) {
  return Builder.CreateVectorSplat(
      16, ConstantFP::get(Context, APFloat(Value)), "const");
}
