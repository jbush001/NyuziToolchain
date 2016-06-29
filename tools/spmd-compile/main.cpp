#include "AstNode.h"
#include "SPMDBuilder.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/CodeGen/CommandFlags.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Scalar.h"
#include <cctype>
#include <cstdio>
#include <map>
#include <string>
#include <vector>
using namespace llvm;

static Module *TheModule;

int parse(Module *, LLVMContext&);

bool generateTargetCode(Module *TheModule) {
  std::string ErrStr;
  llvm::legacy::PassManager PM;

  Triple TheTriple;
  TheTriple.setTriple(sys::getDefaultTargetTriple());

  std::error_code Error;
  std::string ErrString;
  const Target *TheTarget =
      TargetRegistry::lookupTarget(std::string(""), TheTriple, ErrString);
  if (!TheTarget) {
    errs() << ErrString;
    return false;
  }

  TargetOptions Options;
  Options.MCOptions.AsmVerbose = true;
  std::unique_ptr<TargetMachine> target(TheTarget->createTargetMachine(
      TheTriple.getTriple(), "", "", Options, getRelocModel(),
      CodeModel::Default, CodeGenOpt::Aggressive));
  TargetMachine &Target = *target.get();
  TheModule->setDataLayout(Target.createDataLayout());

  raw_fd_ostream Raw("-", Error, llvm::sys::fs::F_Text);

  PM.add(createPromoteMemoryToRegisterPass());
  PM.add(createInstructionCombiningPass());
  PM.add(createReassociatePass());
  PM.add(createCFGSimplificationPass());

  if (Target.addPassesToEmitFile(PM, Raw, TargetMachine::CGFT_AssemblyFile,
                                 true, 0, 0)) {
    errs() << "target does not support generation of this"
           << " file type!\n";
    return false;
  }

  PM.run(*TheModule);
  return true;
}

int main(int argc, const char *argv[]) {
  sys::PrintStackTraceOnErrorSignal(argv[0]);
  PrettyStackTraceProgram X(argc, argv);

  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  LLVMContext TheContext;
  TheModule = new Module("my module", TheContext);

  if (!parse(TheModule, TheContext))
    return 1;

  TheModule->dump();
  if (!generateTargetCode(TheModule))
    return 1;

  return 0;
}
