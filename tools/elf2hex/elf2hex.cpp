
//
// This tool is specific to the GPGPU target.
// Convert a statically linked ELF executable into its in-memory representation
// and write it out in hex format compatible with a Verilog simulator's
// $readmemh function.  This overwrites the low address of
// the binary with a jump to the entry point (this clobbers the ELF header, which is
// unused).
//
// Jeff Bush 2013
//

#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <llvm/Support/Compiler.h>
#include <llvm/BinaryFormat/ELF.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

using namespace llvm::ELF;
using namespace llvm;

namespace {

cl::opt<std::string>
InputFilename(cl::Positional, cl::desc("<input ELF file>"), cl::init("a.out"));

cl::opt<std::string> OutputFilename("o", cl::desc("Output hex file"),
                                    cl::value_desc("filename"));

// The base offset allows initially loading at a different address than the
// executable is linked at. It is used for booting kernels.
cl::opt<unsigned int> BaseOffset("b", cl::desc("Base Offset"),
                                  cl::init(0));

int writeHex(FILE *outputFile, FILE *inputFile, int length) {
  for (int i = 0; i < length; i++) {
      int c = fgetc(inputFile);
      if (c == EOF) {
        errs() << "Unexpected end of file\n";
        return -1;
      }

      fprintf(outputFile, "%02x", c);
      if ((i & 3) == 3)
        fprintf(outputFile, "\n");
  }

  return 0;
}

int writeZeros(FILE *outputFile, int length) {
  for (int i = 0; i < length / 4; i++) {
    if (fprintf(outputFile, "00000000\n") < 0) {
      errs() << "Error writing to output file\n" << strerror(errno) << "\n";
      return -1;
    }
  }

  return 0;
}

}  // namespace

int main(int argc, const char *argv[]) {
  cl::ParseCommandLineOptions(argc, argv, "elf2hex converter\n");

  FILE *inputFile = fopen(InputFilename.c_str(), "rb");
  if (!inputFile) {
    errs() << "Error opening input file: " << strerror(errno) << "\n";;
    return 1;
  }

  Elf32_Ehdr eheader;
  if (fread(&eheader, sizeof(eheader), 1, inputFile) != 1) {
    errs() << "Error reading header: " << strerror(errno) << "\n";
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

  Elf32_Phdr *pheader = (Elf32_Phdr*) calloc(sizeof(Elf32_Phdr), eheader.e_phnum);
  fseek(inputFile, eheader.e_phoff, SEEK_SET);
  if (fread(pheader, sizeof(Elf32_Phdr), eheader.e_phnum, inputFile) !=
      eheader.e_phnum) {
    errs() << "error reading program header " << strerror(errno) << "\n";
    return 1;
  }

  FILE *outputFile = fopen(OutputFilename.c_str(), "wb");
  if (!outputFile) {
    errs() << "Error opening output file: " << strerror(errno) << "\n";
    return 1;
  }

  fprintf(outputFile, "// Converted from %s by elf2hex\n", InputFilename.c_str());

  bool first = true;
  for (int segment = 0; segment < eheader.e_phnum; segment++) {
    if (pheader[segment].p_type == PT_LOAD) {
      fprintf(outputFile, "@%08x\n", (pheader[segment].p_vaddr - BaseOffset) / 4);
      if (fseek(inputFile, pheader[segment].p_offset, SEEK_SET) < 0) {
        errs() << "Error reading segment " << segment << ": "
          << strerror(errno) << "\n";
        return 1;
      }

      int sizeToCopy = pheader[segment].p_filesz;
      if (first) {
        // Replace the first word with a jump instruction to the
        // appropriate location
        // XXX assumes loadable segments are ordered by virtual address
        int offset = eheader.e_entry - pheader[segment].p_vaddr;
        uint32_t instruction = 0xf6000000 | (offset / 4);
        fprintf(outputFile, "%02x%02x%02x%02x\n",
          instruction & 0xff,
          (instruction >> 8) & 0xff,
          (instruction >> 16) & 0xff,
          (instruction >> 24) & 0xff);
        sizeToCopy -= 4;
        fseek(inputFile, 4, SEEK_CUR);
        first = false;
      }

      if (writeHex(outputFile, inputFile, sizeToCopy) < 0) {
        return 1;
      }

      int zeroFill = pheader[segment].p_memsz - pheader[segment].p_filesz;
      if (zeroFill > 0) {
        if (writeZeros(outputFile, zeroFill) < 0) {
          return 1;
        }
      }
    }
  }

  fclose(inputFile);
  fclose(outputFile);

  return 0;
}
