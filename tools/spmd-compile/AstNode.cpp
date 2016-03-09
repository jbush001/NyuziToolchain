#include "AstNode.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

Value *SubAst::generate(SPMDBuilder &Builder) {
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);

  return Builder.createSub(Op1Val, Op2Val);
}

Value *AddAst::generate(SPMDBuilder &Builder) {
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);

  return Builder.createAdd(Op1Val, Op2Val);
}

Value *MulAst::generate(SPMDBuilder &Builder) {
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);

  return Builder.createMul(Op1Val, Op2Val);
}

Value *DivAst::generate(SPMDBuilder &Builder) {
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);

  return Builder.createDiv(Op1Val, Op2Val);
}

Value *AssignAst::generate(SPMDBuilder &Builder) {
  return Builder.assignLocalVariable(static_cast<VariableAst *>(Lhs)->Sym->Val,
                                     Rhs->generate(Builder));
}

Value *IfAst::generate(SPMDBuilder &Builder) {
  Builder.pushMask(Cond->generate(Builder));
  if (Else) {
    llvm::BasicBlock *ThenBB = Builder.createBasicBlock("then");
    llvm::BasicBlock *ElseTopBB = Builder.createBasicBlock("elsetop");
    llvm::BasicBlock *ElseBodyBB = Builder.createBasicBlock("elsebody");
    llvm::BasicBlock *EndifBB = Builder.createBasicBlock("endif");

    // Skip threads that aren't active for 'then' block
    Builder.shortCircuitZeroMask(ElseTopBB, ThenBB);

    // Generate 'then'
    Builder.setInsertPoint(ThenBB);
    Then->generate(Builder);
    Builder.branch(ElseTopBB);

    // Invert active mask
    Builder.setInsertPoint(ElseTopBB);
    Builder.invertLastPushedMask();
    Builder.shortCircuitZeroMask(EndifBB, ElseBodyBB);

    // Generate 'else'
    Builder.setInsertPoint(ElseBodyBB);
    Else->generate(Builder);
    Builder.branch(EndifBB);
    Builder.setInsertPoint(EndifBB);
  } else {
    llvm::BasicBlock *ThenBB = Builder.createBasicBlock("then");
    llvm::BasicBlock *EndifBB = Builder.createBasicBlock("endif");
    Builder.shortCircuitZeroMask(EndifBB, ThenBB);
    Builder.setInsertPoint(ThenBB);
    Then->generate(Builder);
    Builder.setInsertPoint(EndifBB);
  }

  Builder.popMask();
  return nullptr;
}

Value *WhileAst::generate(SPMDBuilder &Builder) {
  llvm::BasicBlock *LoopTopBB = Builder.createBasicBlock("looptop");
  llvm::BasicBlock *LoopBodyBB = Builder.createBasicBlock("loopbody");
  llvm::BasicBlock *LoopEndBB = Builder.createBasicBlock("loopbody");

  // Loop check
  Builder.branch(LoopTopBB);
  Builder.setInsertPoint(LoopTopBB);
  Value *LoopCond = Cond->generate(Builder);
  Builder.pushMask(LoopCond);
  Builder.shortCircuitZeroMask(LoopEndBB, LoopBodyBB);

  // Loop body
  Builder.setInsertPoint(LoopBodyBB);
  Body->generate(Builder);
  Builder.branch(LoopTopBB);
  Builder.popMask();
  Builder.setInsertPoint(LoopEndBB);
  return nullptr;
}

Value *VariableAst::generate(SPMDBuilder &Builder) {
  if (Sym->Val == nullptr)
    Sym->Val = Builder.createLocalVariable(Sym->Name.c_str());

  return Builder.readLocalVariable(Sym->Val);
}

Value *CompareAst::generate(SPMDBuilder &Builder) {
  Value *Op1Val = Op1->generate(Builder);
  Value *Op2Val = Op2->generate(Builder);

  return Builder.createCompare(Type, Op1Val, Op2Val);
}

Value *SequenceAst::generate(SPMDBuilder &Builder) {
  if (Stmt)
    Stmt->generate(Builder);
  if (Next)
    Next->generate(Builder);

  return nullptr;
}

Value *ReturnAst::generate(SPMDBuilder &Builder) {
  Value *RetVal = RetNode->generate(Builder);
  Builder.createReturn(RetVal);
  return RetVal;
}

Value *ConstantAst::generate(SPMDBuilder &Builder) {
  return Builder.createConstant(Value);
}
