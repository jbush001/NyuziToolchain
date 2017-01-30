#include "SPMDBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

SPMDBuilder::SPMDBuilder(Module *Mod, LLVMContext &_Context)
    : Context(_Context), Builder(_Context), MainModule(Mod), CurrentFunction(nullptr) {
  VMixFInt = llvm::Intrinsic::getDeclaration(
      MainModule, (llvm::Intrinsic::ID)Intrinsic::nyuzi_vector_mixf, None);
  sFloatType = Type::getFloatTy(Context);
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
  ReturnMaskPtr = Builder.CreateAlloca(Type::getInt32Ty(Context), 0, "return_mask");
  Builder.CreateStore(ConstantInt::get(Type::getInt32Ty(Context), 0xffffLL), ReturnMaskPtr);

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
        NewReturnMask, ConstantInt::get(Context, APInt(32, 0)));

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
    Value *Ops[] = {ActiveLanes, NewValue, OldValue};
    Value *Blended = Builder.CreateCall(VMixFInt, Ops);
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
      ActiveLanes, ConstantInt::get(Context, APInt(32, 0)));
  Builder.CreateCondBr(BoolCond, SkipTo, Next);
}

void SPMDBuilder::branch(llvm::BasicBlock *Dest) { Builder.CreateBr(Dest); }

Value *SPMDBuilder::createCompare(CmpInst::Predicate Type, Value *lhs,
                                  Value *rhs) {
  unsigned IntrinsicId;
  switch (Type) {
  case CmpInst::FCMP_OEQ:
  case CmpInst::FCMP_UEQ:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_eq;
    break;

  case CmpInst::FCMP_ONE:
  case CmpInst::FCMP_UNE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_ne;
    break;

  case CmpInst::FCMP_OGT:
  case CmpInst::FCMP_UGT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_gt;
    break;

  case CmpInst::FCMP_OGE:
  case CmpInst::FCMP_UGE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_ge;
    break;

  case CmpInst::FCMP_OLT:
  case CmpInst::FCMP_ULT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_lt;
    break;

  case CmpInst::FCMP_OLE:
  case CmpInst::FCMP_ULE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpf_le;
    break;

  case CmpInst::ICMP_EQ:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_eq;
    break;

  case CmpInst::ICMP_NE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_ne;
    break;

  case CmpInst::ICMP_UGT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_ugt;
    break;

  case CmpInst::ICMP_UGE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_ugt;
    break;

  case CmpInst::ICMP_ULT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_ult;
    break;

  case CmpInst::ICMP_ULE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_ule;
    break;

  case CmpInst::ICMP_SGT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_sgt;
    break;

  case CmpInst::ICMP_SGE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_sge;
    break;

  case CmpInst::ICMP_SLT:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_slt;
    break;

  case CmpInst::ICMP_SLE:
    IntrinsicId = Intrinsic::nyuzi_mask_cmpi_sle;
    break;

  default:
    llvm_unreachable("Unknown comparision type");
  }

  Function *CompareFunc =
      Intrinsic::getDeclaration(MainModule, (Intrinsic::ID)IntrinsicId, None);

  SmallVector<Value *, 2> Ops;
  Ops.push_back(lhs);
  Ops.push_back(rhs);

  return Builder.CreateCall(CompareFunc, Ops, "pred");
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
