#include "SPMDBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Debug.h"
#include "llvm/IR/Intrinsics.h"

using namespace llvm;

SPMDBuilder::SPMDBuilder(Module *Mod)
  : Builder(getGlobalContext()),
    MainModule(Mod),
    CurrentFunction(nullptr) {
}

SPMDBuilder::~SPMDBuilder() {
}

void SPMDBuilder::startFunction(const char *name) {
  CurrentFunction = cast<Function>(MainModule->getOrInsertFunction(name, 
                                  Type::getInt32Ty(getGlobalContext()),
                                  Type::getInt32Ty(getGlobalContext()),
                                  (Type *)0));
  BasicBlock *BB = BasicBlock::Create(getGlobalContext(), "Entry", CurrentFunction);
  Builder.SetInsertPoint(BB);
}

void SPMDBuilder::endFunction() {
}

void SPMDBuilder::createReturn(llvm::Value *ReturnValue) {
  Builder.CreateRet(ReturnValue);
}


llvm::Value *SPMDBuilder::createLocalVariable(const char *Name) {
  return Builder.CreateAlloca(VectorType::get(Type::getFloatTy(getGlobalContext()), 
                              16), 0, Name);
}

llvm::Value *SPMDBuilder::readLocalVariable(llvm::Value *Variable) {
  return Builder.CreateLoad(Variable);
}

void SPMDBuilder::assignLocalVariable(Value *Variable, Value *NewValue)
{
  if (MaskStack.empty()) {
    Builder.CreateStore(NewValue, Variable);
  } else {
    // Need to predicate this instruction
    Value *CurrentMaskVal = Builder.CreateLoad(getCurrentMask());
    llvm::Function *BlendFunc = llvm::Intrinsic::getDeclaration(MainModule, 
                                (llvm::Intrinsic::ID) Intrinsic::vp_vector_mixf,
                                None);

    Value *OldValue = Builder.CreateLoad(Variable);

    SmallVector<Value*, 3> Ops;
    Ops.push_back(CurrentMaskVal);
    Ops.push_back(NewValue);
    Ops.push_back(OldValue);

    Value *Blended = Builder.CreateCall(BlendFunc, Ops, "");
    Builder.CreateStore(Blended, Variable);
  }
}

void SPMDBuilder::pushMask(Value *MaskValue) {
  Value *MaskLocation = Builder.CreateAlloca(Type::getInt32Ty(getGlobalContext()), 0, "mask");
  if (MaskStack.empty()) {
    Builder.CreateStore(MaskValue, MaskLocation);
    MaskStackEntry Entry = { MaskLocation, MaskLocation };
    MaskStack.push_back(Entry);
  } else {
    Value *PreviousMaskVal = Builder.CreateLoad(getCurrentMask());
    Value *NewMaskValue = Builder.CreateAnd(MaskValue, PreviousMaskVal);
    Builder.CreateStore(NewMaskValue, MaskLocation);
    MaskStackEntry Entry = { MaskLocation, getCurrentMask() };
    MaskStack.push_back(Entry);
  }
}

void SPMDBuilder::popMask() {
    MaskStack.pop_back();
}

void SPMDBuilder::invertLastPushedMask() {
  MaskStackEntry PreviousTop = MaskStack.back();
  MaskStack.pop_back();

  Value *LastPredicate = Builder.CreateLoad(PreviousTop.ThisMask);
  Value *InvertedMask = Builder.CreateNot(LastPredicate);

  Value *NewMask = InvertedMask;
  if (!MaskStack.empty()) {
    Value *PreviousMaskVal = Builder.CreateLoad(getCurrentMask());
    NewMask = Builder.CreateAnd(InvertedMask, PreviousMaskVal);
  }
  
  Value *NewMaskLoc = Builder.CreateAlloca(Type::getInt32Ty(getGlobalContext()), 0, "mask");
  Value *InvertedMaskLoc = Builder.CreateAlloca(Type::getInt32Ty(getGlobalContext()), 0, "mask");
  Builder.CreateStore(NewMask, NewMaskLoc);
  Builder.CreateStore(InvertedMask, InvertedMaskLoc);

  MaskStackEntry NewTop = { NewMaskLoc, InvertedMaskLoc };
  MaskStack.push_back(NewTop);
}

Value *SPMDBuilder::getCurrentMask() {
  return MaskStack.back().CombinedValue;
}

void SPMDBuilder::shortCircuitZeroMask(llvm::BasicBlock *SkipTo, llvm::BasicBlock *Next) {
  Value *CurrentMaskVal = Builder.CreateLoad(getCurrentMask());
  Builder.CreateCondBr(CurrentMaskVal, Next, SkipTo);
}

Value *SPMDBuilder::createCompare(CmpInst::Predicate Type, Value *lhs, Value *rhs) {
  unsigned IntrinsicId;
  switch (Type) {              
    case CmpInst::FCMP_OEQ: 
    case CmpInst::FCMP_UEQ: 
      // XXX need to cast parameters
      IntrinsicId = Intrinsic::vp_mask_cmpi_eq;
      break;

    case CmpInst::FCMP_ONE: 
    case CmpInst::FCMP_UNE: 
      // XXX need to cast parameters
      IntrinsicId = Intrinsic::vp_mask_cmpi_ne;
      break;

    case CmpInst::FCMP_OGT: 
    case CmpInst::FCMP_UGT: 
      IntrinsicId = Intrinsic::vp_mask_cmpf_gt;
      break;

    case CmpInst::FCMP_OGE: 
    case CmpInst::FCMP_UGE: 
      IntrinsicId = Intrinsic::vp_mask_cmpf_ge;
      break;
      
    case CmpInst::FCMP_OLT: 
    case CmpInst::FCMP_ULT: 
      IntrinsicId = Intrinsic::vp_mask_cmpf_lt;
      break;

    case CmpInst::FCMP_OLE: 
    case CmpInst::FCMP_ULE: 
      IntrinsicId = Intrinsic::vp_mask_cmpf_le;
      break;

    case CmpInst::ICMP_EQ:
      IntrinsicId = Intrinsic::vp_mask_cmpi_eq;
      break;

    case CmpInst::ICMP_NE:
      IntrinsicId = Intrinsic::vp_mask_cmpi_ne;
      break;

    case CmpInst::ICMP_UGT: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_ugt;
      break;

    case CmpInst::ICMP_UGE: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_ugt;
      break;

    case CmpInst::ICMP_ULT: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_ult;
      break;

    case CmpInst::ICMP_ULE: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_ule;
      break;

    case CmpInst::ICMP_SGT: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_sgt;
      break;

    case CmpInst::ICMP_SGE: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_sge;
      break;

    case CmpInst::ICMP_SLT: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_slt;
      break;

    case CmpInst::ICMP_SLE: 
      IntrinsicId = Intrinsic::vp_mask_cmpi_sle;
      break;
      
    default:
      llvm_unreachable("Unknown comparision type");
  }

  Function *CompareFunc = Intrinsic::getDeclaration(MainModule, 
                              (Intrinsic::ID) IntrinsicId,
                              None);

  SmallVector<Value*, 2> Ops;
  Ops.push_back(lhs);
  Ops.push_back(rhs);
  
  return Builder.CreateCall(CompareFunc, Ops, "");
}

Value *SPMDBuilder::createAdd(Value *Lhs, Value *Rhs) {
    return Builder.CreateFAdd(Lhs, Rhs);
}

BasicBlock *SPMDBuilder::createBasicBlock(const char *name) {
	return BasicBlock::Create(getGlobalContext(), name, CurrentFunction);
}

void SPMDBuilder::setInsertPoint(BasicBlock *BB) {
  Builder.SetInsertPoint(BB);
}

