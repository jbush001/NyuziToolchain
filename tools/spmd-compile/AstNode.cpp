#include "llvm/Support/Debug.h"
#include "AstNode.h"

using namespace llvm;

Value *BinaryAst::generate(SPMDBuilder &Builder)
{
	Value *Op1Val = Op1->generate(Builder);
	Value *Op2Val = Op2->generate(Builder);
		
	return Builder.createSub(Op1Val, Op2Val);
}

Value *AssignAst::generate(SPMDBuilder &Builder)
{
	Builder.assignLocalVariable(static_cast<VariableAst*>(Lhs)->Var, Rhs->generate(Builder));
}

Value *IfAst::generate(SPMDBuilder &Builder)
{
	Builder.pushMask(Cond->generate(Builder));
	Then->generate(Builder);
	if (Else) {
//		llvm::BasicBlock *ElseBB = Builder.createBasicBlock("else");
//		llvm::BasicBlock *EndIfBB = Builder.createBasicBlock("endif");
//		Builder.setInsertPoint(ElseBB);
//		Builder.shortCircuitZeroMask(EndIfBB, ElseBB);
		Builder.invertLastPushedMask();
		Else->generate(Builder);
//		Builder.setInsertPoint(EndIfBB);
	}

	Builder.popMask();	
	return nullptr;
}

Value *VariableAst::generate(SPMDBuilder &Builder)
{
	return Builder.readLocalVariable(Var);
}

Value *CompareAst::generate(SPMDBuilder &Builder)
{
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);
  
  return Builder.createCompare(Type, Op1Val, Op2Val);
}

Value *SequenceAst::generate(SPMDBuilder &Builder){
	for (auto *Node : Nodes)
		Node->generate(Builder);

	return nullptr;
}

Value *ReturnAst::generate(SPMDBuilder &Builder) {
  Value *RetVal = RetNode->generate(Builder);
  Builder.createReturn(RetVal);
}

