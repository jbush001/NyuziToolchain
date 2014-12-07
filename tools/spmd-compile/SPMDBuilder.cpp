#include "SPMDBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/Debug.h"
#include "llvm/IR/Intrinsics.h"

using namespace llvm;

SPMDBuilder::SPMDBuilder(Module *Mod)
  : Builder(getGlobalContext()),
    MainModule(Mod),
    CurrentFunction(nullptr) {

  VMixFInt = llvm::Intrinsic::getDeclaration(MainModule, 
                                (llvm::Intrinsic::ID) Intrinsic::nyuzi_vector_mixf,
                                None);
}

SPMDBuilder::~SPMDBuilder() {
}

void SPMDBuilder::startFunction(const char *Name, const std::vector<std::string> 
  &ArgNames) {
  Type *VecF = VectorType::get(Type::getFloatTy(getGlobalContext()), 16);
  std::vector<Type*> Params(ArgNames.size(), VecF);
  FunctionType *FT = FunctionType::get(VecF, Params, false);
  CurrentFunction = Function::Create(FT, Function::ExternalLinkage, Name, MainModule);

  BasicBlock *BB = BasicBlock::Create(getGlobalContext(), "Entry", CurrentFunction);
  Builder.SetInsertPoint(BB);
  
	unsigned Idx = 0;
	for (Function::arg_iterator AI = CurrentFunction->arg_begin(); 
		Idx != ArgNames.size(); ++AI, ++Idx)
	{
  	AI->setName(ArgNames[Idx]);
	}
  
  Result = createLocalVariable("result");
}

void SPMDBuilder::endFunction() {
  Builder.CreateRet(readLocalVariable(Result));
}

llvm::Function::arg_iterator SPMDBuilder::getFuncArguments() {
  return CurrentFunction->arg_begin();
}

void SPMDBuilder::createReturn(llvm::Value *ReturnValue) {
  assignLocalVariable(Result, ReturnValue);
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
    Value *OldValue = Builder.CreateLoad(Variable);
    Value *Blended = Builder.CreateCall3(VMixFInt, 
      getCurrentMask(), NewValue, OldValue, "whatisthisname");
    Builder.CreateStore(Blended, Variable);
  }
}

void SPMDBuilder::pushMask(Value *MaskValue) {
  if (MaskStack.empty()) {
    MaskStackEntry Entry = { MaskValue, MaskValue };
    MaskStack.push_back(Entry);
  } else {
    Value *NewCombinedValue = Builder.CreateAnd(MaskValue, getCurrentMask());
    MaskStackEntry Entry = { MaskValue, NewCombinedValue };
    MaskStack.push_back(Entry);
  }
}

void SPMDBuilder::popMask() {
    MaskStack.pop_back();
}

void SPMDBuilder::invertLastPushedMask() {
  MaskStackEntry PreviousTop = MaskStack.back();
  MaskStack.pop_back();

  Value *NewMask = Builder.CreateNot(PreviousTop.ThisMask);
  Value *NewCombined = NewMask;
  if (!MaskStack.empty())
    NewCombined = Builder.CreateAnd(NewMask, getCurrentMask());
  
  MaskStackEntry NewTop = { NewMask, NewCombined };
  MaskStack.push_back(NewTop);
}

Value *SPMDBuilder::getCurrentMask() {
  return MaskStack.back().CombinedValue;
}

void SPMDBuilder::shortCircuitZeroMask(llvm::BasicBlock *SkipTo, llvm::BasicBlock *Next) {
  llvm::Value *BoolCond = Builder.CreateICmpEQ(getCurrentMask(),
    ConstantInt::get(getGlobalContext(), APInt(32, 0)));
  Builder.CreateCondBr(BoolCond, SkipTo, Next);
}

void SPMDBuilder::branch(llvm::BasicBlock *Dest) {
  Builder.CreateBr(Dest);
}

Value *SPMDBuilder::createCompare(CmpInst::Predicate Type, Value *lhs, Value *rhs) {
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

  Function *CompareFunc = Intrinsic::getDeclaration(MainModule, 
                              (Intrinsic::ID) IntrinsicId,
                              None);

  SmallVector<Value*, 2> Ops;
  Ops.push_back(lhs);
  Ops.push_back(rhs);
  
  return Builder.CreateCall(CompareFunc, Ops, "");
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
	return BasicBlock::Create(getGlobalContext(), name, CurrentFunction);
}

void SPMDBuilder::setInsertPoint(BasicBlock *BB) {
  Builder.SetInsertPoint(BB);
}

Value *SPMDBuilder::createConstant(float Value) {
  return Builder.CreateVectorSplat(16, ConstantFP::get(getGlobalContext(), APFloat(Value)));
}



