//===-- VectorProc.td - Describe the VectorProc Target Machine -------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// VECTORPROC Subtarget features.
//
 
def FeatureV9
  : SubtargetFeature<"v9", "IsV9", "true",
                     "Enable VECTORPROC-V9 instructions">;
def FeatureV8Deprecated
  : SubtargetFeature<"deprecated-v8", "V8DeprecatedInsts", "true",
                     "Enable deprecated V8 instructions in V9 mode">;
def FeatureVIS
  : SubtargetFeature<"vis", "IsVIS", "true",
                     "Enable UltraVECTORPROC Visual Instruction Set extensions">;

//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "VectorProcRegisterInfo.td"
include "VectorProcCallingConv.td"
include "VectorProcInstrInfo.td"

def VectorProcInstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// VECTORPROC processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic",         []>;
def : Proc<"v8",              []>;
def : Proc<"supervectorproc",      []>;
def : Proc<"vectorproclite",       []>;
def : Proc<"f934",            []>;
def : Proc<"hypervectorproc",      []>;
def : Proc<"vectorproclite86x",    []>;
def : Proc<"vectorproclet",        []>;
def : Proc<"tsc701",          []>;
def : Proc<"v9",              [FeatureV9]>;
def : Proc<"ultravectorproc",      [FeatureV9, FeatureV8Deprecated]>;
def : Proc<"ultravectorproc3",     [FeatureV9, FeatureV8Deprecated]>;
def : Proc<"ultravectorproc3-vis", [FeatureV9, FeatureV8Deprecated, FeatureVIS]>;


//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def VectorProc : Target {
  // Pull in Instruction Info:
  let InstructionSet = VectorProcInstrInfo;
}
