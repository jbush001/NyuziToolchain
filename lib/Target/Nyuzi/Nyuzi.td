//===-- Nyuzi.td - Describe the Nyuzi Target Machine -------*- tablegen -*-===//
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

include "NyuziRegisterInfo.td"
include "NyuziCallingConv.td"
include "NyuziSchedule.td"
include "NyuziInstrInfo.td"

def NyuziInstrInfo : InstrInfo;

def NyuziAsmParser : AsmParser {
  let ShouldEmitMatchRegisterName = 1;
}

def NyuziAsmWriter : AsmWriter {
  string AsmWriterClassName  = "InstPrinter";
  bit isMCAsmWriter = 1;
}

def : Processor<"nyuzi", NyuziItineraries, []>;

def Nyuzi : Target {
  let InstructionSet = NyuziInstrInfo;
  let AssemblyWriters = [NyuziAsmWriter];
  let AssemblyParsers = [NyuziAsmParser];
}
