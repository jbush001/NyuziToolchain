#ifndef __AST_NODE_H
#define __AST_NODE_H

#include "SPMDBuilder.h"

class AstNode {
public:
	virtual llvm::Value *generate(SPMDBuilder&) = 0;
};

class SubAst : public AstNode {
public:
	SubAst(AstNode *_Op1, AstNode *_Op2)
		: Op1(_Op1), Op2(_Op2)
	{}
		
	virtual llvm::Value *generate(SPMDBuilder&);

private:
	AstNode *Op1;
	AstNode *Op2;
};

class AssignAst : public AstNode {
public:
	AssignAst(AstNode *_Lhs, AstNode *_Rhs)
    : Lhs(_Lhs), Rhs(_Rhs)
	{}

	virtual llvm::Value *generate(SPMDBuilder&);
	
private:	
	AstNode *Lhs;
	AstNode *Rhs;
};

class IfAst : public AstNode {
public:
	IfAst(AstNode *_Cond, AstNode *_Then, AstNode *_Else)
		:	Cond(_Cond),
			Then(_Then),
			Else(_Else)
	{}

	virtual llvm::Value *generate(SPMDBuilder&);
	
private:
	AstNode *Cond;
	AstNode *Then;
	AstNode *Else;	
};

class WhileAst : public AstNode {
public:   
    WhileAst(AstNode *_Cond, AstNode *_Body)
        : Cond(_Cond),
          Body(_Body)
    {}
        
    virtual llvm::Value *generate(SPMDBuilder&);

private:
    AstNode *Cond;
    AstNode *Body;
};

class VariableAst : public AstNode {
public:
	VariableAst(llvm::Value *_Var)
		: Var(_Var)
	{}
		
	virtual llvm::Value *generate(SPMDBuilder&);

private:
	llvm::Value *Var;	
	friend class AssignAst;
};

class CompareAst : public AstNode {
public:
  CompareAst(llvm::CmpInst::Predicate _Type, AstNode *_Op1, AstNode *_Op2)
    : Type(_Type), Op1(_Op1), Op2(_Op2)
  {}

	virtual llvm::Value *generate(SPMDBuilder&);
  
private: 
  llvm::CmpInst::Predicate Type;
  AstNode *Op1;
  AstNode *Op2;
};

class SequenceAst : public AstNode {
public:
    SequenceAst() {}
    
    void addNode(AstNode *Node) {
      Nodes.push_back(Node);
    }

	virtual llvm::Value *generate(SPMDBuilder&);
  
private:
  std::vector<AstNode*> Nodes;
};

class ReturnAst : public AstNode {
public:
  ReturnAst(AstNode *_RetNode)
    : RetNode(_RetNode)
  {}

	virtual llvm::Value *generate(SPMDBuilder&);
  
private:
  AstNode *RetNode;
};

class ConstantAst : public AstNode {
public:
  ConstantAst(float _Value)
    : Value(_Value)
  {}

	virtual llvm::Value *generate(SPMDBuilder&);
    
private:
  float Value;    
};

#endif
