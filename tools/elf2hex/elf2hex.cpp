
//
// This tool is specific to the GPGPU target.
// Convert a statically linked ELF executable into its in-memory representation
// and write it out in hex format compatible with a Verilog simulator's
// $readmemh function.  Because LLD doesn't support linker scripts, we can't
// make a proper boot.  As a hack around this, this overwrites the low address of
// the binary with a jump to the entry point (this clobbers the ELF header, which is
// unused).
//
// Jeff Bush 2013
//

#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include <llvm/Support/Compiler.h>
#include <llvm/Support/ELF.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

using namespace llvm::ELF;
using namespace llvm;

static cl::opt<std::string>
InputFilename(cl::Positional, cl::desc("<input ELF file>"), cl::init("a.out"));

static cl::opt<std::string> OutputFilename("o", cl::desc("Output hex file"),
                                           cl::value_desc("filename"));
static cl::opt<unsigned int> BaseAddress("b", cl::desc("Base Address"),
                                           cl::init(0));

int main(int argc, const char *argv[]) {
  cl::ParseCommandLineOptions(argc, argv, "elf2hex converter\n");

  FILE *inputFile = fopen(InputFilename.c_str(), "rb");
  if (!inputFile) {
    errs() << "Error opening input file\n";
    return 1;
  }

  Elf32_Ehdr eheader;
  if (fread(&eheader, sizeof(eheader), 1, inputFile) != 1) {
    errs() << "Error reading header\n";
    return 1;
  }

  if (memcmp(eheader.e_ident, ElfMagic, 4) != 0) {
    errs() << "Not an elf file\n";
    return 1;
  }
  
  if (eheader.e_machine != EM_NYUZI) {
    errs() << "Incorrect architecture\n";
    return 1;
  }

  if (eheader.e_phoff == 0) {
    errs() << "File has no program header\n";
    return 1;
  }

  Elf32_Phdr *pheader = (Elf32_Phdr *)calloc(sizeof(Elf32_Phdr), eheader.e_phnum);
  fseek(inputFile, eheader.e_phoff, SEEK_SET);
  if (fread(pheader, sizeof(Elf32_Phdr), eheader.e_phnum, inputFile) !=
      eheader.e_phnum) {
    errs() << "error reading program header\n";
    return 1;
  }

  // Walk throught the segments and find the highest address
  unsigned int maxAddress = 0;
  for (int segment = 0; segment < eheader.e_phnum; segment++) {
    unsigned int highAddr = pheader[segment].p_vaddr + pheader[segment].p_memsz;
    if (highAddr > maxAddress)
      maxAddress = highAddr;
    
    if (pheader[segment].p_vaddr < BaseAddress) {
      errs() << "Program segment comes before base address\n";
      return 1;
    }
  }

  unsigned char *memoryImage = (unsigned char *)calloc(maxAddress - BaseAddress, 1);
  if (!memoryImage) {
    errs() << "not enough memory for program image\n";
    return 1;
  }

  for (int segment = 0; segment < eheader.e_phnum; segment++) {
    if (pheader[segment].p_type == PT_LOAD) {
      fseek(inputFile, pheader[segment].p_offset, SEEK_SET);
      if (fread(memoryImage + pheader[segment].p_vaddr - BaseAddress, 1,
                pheader[segment].p_filesz,
                inputFile) != pheader[segment].p_filesz) {
        errs() << "Error reading segment " << segment << "\n";
        return 1;
      }
    }
  }

  fclose(inputFile);

  // Convert the first word into a jump instruction to the appropriate location
  *((unsigned int *)memoryImage) = 0xf6000000 | ((eheader.e_entry - 4 - BaseAddress) << 5);

  FILE *outputFile = fopen(OutputFilename.c_str(), "wb");
  if (!outputFile) {
    errs() << "error opening output file";
    return 1;
  }

  for (unsigned int i = 0; i < maxAddress - BaseAddress; i++) {
    fprintf(outputFile, "%02x", memoryImage[i]);
    if ((i & 3) == 3)
      fprintf(outputFile, "\n");
  }

  fclose(outputFile);

  return 0;
}
