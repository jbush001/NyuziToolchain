#include "llvm/Support/Debug.h"
#include "AstNode.h"

using namespace llvm;

Value *SubAst::generate(SPMDBuilder &Builder)
{
	Value *Op1Val = Op1->generate(Builder);
	Value *Op2Val = Op2->generate(Builder);
		
	return Builder.createSub(Op1Val, Op2Val);
}

Value *AddAst::generate(SPMDBuilder &Builder)
{
	Value *Op1Val = Op1->generate(Builder);
	Value *Op2Val = Op2->generate(Builder);
		
	return Builder.createAdd(Op1Val, Op2Val);
}

Value *MulAst::generate(SPMDBuilder &Builder)
{
	Value *Op1Val = Op1->generate(Builder);
	Value *Op2Val = Op2->generate(Builder);
		
	return Builder.createMul(Op1Val, Op2Val);
}

Value *DivAst::generate(SPMDBuilder &Builder)
{
	Value *Op1Val = Op1->generate(Builder);
	Value *Op2Val = Op2->generate(Builder);
		
	return Builder.createDiv(Op1Val, Op2Val);
}

Value *AssignAst::generate(SPMDBuilder &Builder)
{
	Builder.assignLocalVariable(static_cast<VariableAst*>(Lhs)->Sym->Val, 
    Rhs->generate(Builder));
}

Value *IfAst::generate(SPMDBuilder &Builder)
{
	Builder.pushMask(Cond->generate(Builder));
	Then->generate(Builder);
	if (Else) {
		Builder.invertLastPushedMask();
		Else->generate(Builder);
	}

	Builder.popMask();	
	return nullptr;
}

Value *WhileAst::generate(SPMDBuilder &Builder)
{
  llvm::BasicBlock *LoopTop = Builder.createBasicBlock("looptop");
  llvm::BasicBlock *LoopBody = Builder.createBasicBlock("loopbody");
  llvm::BasicBlock *LoopEnd = Builder.createBasicBlock("loopbody");
  
  Builder.createBranch(LoopTop);
  Builder.setInsertPoint(LoopTop);
	Value *LoopCond = Cond->generate(Builder);
  Builder.pushMask(LoopCond);
  Builder.shortCircuitZeroMask(LoopEnd, LoopBody); 
  Builder.setInsertPoint(LoopBody);
  Body->generate(Builder);
  Builder.createBranch(LoopTop);
  Builder.popMask();
  Builder.setInsertPoint(LoopEnd);
}

Value *VariableAst::generate(SPMDBuilder &Builder)
{
  if (Sym->Val == nullptr)
    Sym->Val = Builder.createLocalVariable(Sym->Name.c_str());
  
	return Builder.readLocalVariable(Sym->Val);
}

Value *CompareAst::generate(SPMDBuilder &Builder)
{
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);
  
  return Builder.createCompare(Type, Op1Val, Op2Val);
}

Value *SequenceAst::generate(SPMDBuilder &Builder){
  if (Stmt) Stmt->generate(Builder);
  if (Next) Next->generate(Builder);

	return nullptr;
}

Value *ReturnAst::generate(SPMDBuilder &Builder) {
  Value *RetVal = RetNode->generate(Builder);
  Builder.createReturn(RetVal);
}

Value *ConstantAst::generate(SPMDBuilder &Builder) {
  return Builder.createConstant(Value);
}


