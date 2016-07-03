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
#include "llvm/Support/Path.h"
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

int parse(Module *, LLVMContext&);

static Module *TheModule;
extern FILE *yyin;
static cl::opt<std::string> InputFilename(cl::Positional,
                                          cl::desc("<input source file>"),
                                          cl::Required);
static cl::opt<std::string> OutputOption("o", cl::desc("Output filename"),
                                           cl::value_desc("filename"));
static cl::opt<bool> OutputSource("S", cl::desc("Output source code"));
static cl::opt<bool> EmitLLVM("emit-llvm", cl::desc("Output LLVM source"));

bool generateTargetCode(Module *TheModule, raw_fd_ostream &Output) {
  std::string ErrStr;
  llvm::legacy::PassManager PM;

  Triple TheTriple;
  TheTriple.setTriple(sys::getDefaultTargetTriple());

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

  // XXX find a way to add all necessary passes automatically. This probably
  // doesn't cover them all, and there's probably a function somewhere that
  // does the right thing.
  PM.add(createPromoteMemoryToRegisterPass());
  PM.add(createInstructionCombiningPass());
  PM.add(createReassociatePass());
  PM.add(createCFGSimplificationPass());

  TargetMachine::CodeGenFileType FileType = OutputSource
    ? TargetMachine::CGFT_AssemblyFile
    : TargetMachine::CGFT_ObjectFile;
  if (Target.addPassesToEmitFile(PM, Output, FileType,
                                 true, 0, 0)) {
    errs() << "target does not support generation of this"
           << " file type!\n";
    return false;
  }

  PM.run(*TheModule);
  return true;
}

int main(int argc, const char *argv[]) {
  std::error_code Error;
  SmallString<128> OutputPath;

  sys::PrintStackTraceOnErrorSignal(argv[0]);
  PrettyStackTraceProgram X(argc, argv);

  cl::ParseCommandLineOptions(argc, argv, "SPMD Compiler\n");
  yyin = fopen(InputFilename.c_str(), "r");

  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  LLVMContext TheContext;
  TheModule = new Module("my module", TheContext);

  if (!parse(TheModule, TheContext))
    return 1;

  if (OutputOption == "")
  {
    OutputPath = InputFilename;
    if (EmitLLVM)
      sys::path::replace_extension(OutputPath, ".ll");
    else if (OutputSource)
      sys::path::replace_extension(OutputPath, ".S");
    else
      sys::path::replace_extension(OutputPath, ".o");
  }
  else
    OutputPath = OutputOption;

  errs() << "output path is " << OutputPath.c_str() << "\n";
  raw_fd_ostream OutputStream(OutputPath.c_str(), Error, llvm::sys::fs::F_Text);

  if (EmitLLVM)
    TheModule->print(OutputStream, nullptr);
  else if (!generateTargetCode(TheModule, OutputStream))
    return 1;

  return 0;
}
