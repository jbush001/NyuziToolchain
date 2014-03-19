#include "llvm/ADT/Triple.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Transforms/Scalar.h"
#include <cctype>
#include <cstdio>
#include <map>
#include <string>
#include <vector>
#include "SPMDBuilder.h"
#include "AstNode.h"
using namespace llvm;

static Module *TheModule;

void MakeFunction(Module *M)
{
  SPMDBuilder Builder(M);
  Builder.startFunction("test");
  Value *Var1 = Builder.createLocalVariable("foo");
  Value *Var2 = Builder.createLocalVariable("bar");

  AstNode *Cmp = new CompareAst(CmpInst::FCMP_ULE, new VariableAst(Var1), new VariableAst(Var2));
  AstNode *Then = new AssignAst(new VariableAst(Var1), new VariableAst(Var2));
  AstNode *Else = new AssignAst(new VariableAst(Var2), new VariableAst(Var1));
  AstNode *If = new IfAst(Cmp, Then, Else);
  SequenceAst *Seq = new SequenceAst;
  Seq->addNode(If);
  AstNode *Res = new BinaryAst(new VariableAst(Var1), new VariableAst(Var2)); 
  Seq->addNode(new ReturnAst(Res));
  Seq->generate(Builder);

  Builder.endFunction();
}

bool generateCode(Module *TheModule)
{
  std::string ErrStr;
  PassManager PM;

  Triple TheTriple;
  TheTriple.setTriple(sys::getDefaultTargetTriple());

  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(std::string(""), TheTriple,
                                                         Error);
  if (!TheTarget) {
    errs() << Error;
    return false;
  }

  TargetOptions Options;
  OwningPtr<TargetMachine>
    target(TheTarget->createTargetMachine(TheTriple.getTriple(),
                                          "", "", Options,
                                          Reloc::Default, CodeModel::Default, 
                                          CodeGenOpt::Default));
  TargetMachine &Target = *target.get();

  // Override default to generate verbose assembly.
  Target.setAsmVerbosityDefault(true);

  raw_fd_ostream Raw("-", Error, sys::fs::OpenFlags::F_Text);
  formatted_raw_ostream FOS(Raw);
  
  PM.add(createPromoteMemoryToRegisterPass());
  
  if (Target.addPassesToEmitFile(PM, FOS, TargetMachine::CGFT_AssemblyFile, true,
                                 0, 0)) {
    errs() << "target does not support generation of this"
           << " file type!\n";
    return false;
  }

  PM.run(*TheModule);  
  return true;
}

int main(int argc, const char *argv[]) {
  sys::PrintStackTraceOnErrorSignal();
  PrettyStackTraceProgram X(argc, argv);

  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  LLVMContext &Context = getGlobalContext();
  TheModule = new Module("my module", Context);

  // Generate code
  MakeFunction(TheModule);
  
  TheModule->dump();

  // Compile
  if (!generateCode(TheModule))
    return 1;

  return 0;
}
