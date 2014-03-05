//===-- VectorProc.td - Describe the VectorProc Target Machine -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "VectorProcRegisterInfo.td"
include "VectorProcCallingConv.td"
include "VectorProcInstrFormats.td"
include "VectorProcInstrInfo.td"

def VectorProcInstrInfo : InstrInfo;

def VectorProcAsmParser : AsmParser {
  let ShouldEmitMatchRegisterName = 1;
}

def VectorProcAsmWriter : AsmWriter {
  string AsmWriterClassName  = "InstPrinter";
  bit isMCAsmWriter = 1;
}

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;

def VectorProc : Target {
  // Pull in Instruction Info:
  let InstructionSet = VectorProcInstrInfo;
  let AssemblyWriters = [VectorProcAsmWriter];
  let AssemblyParsers = [VectorProcAsmParser];
}
