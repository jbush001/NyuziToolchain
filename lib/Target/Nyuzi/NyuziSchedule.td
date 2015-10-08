//===-- NyuziSchedule.td - Nyuzi Scheduling Definitions ------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

def FU_INT             : FuncUnit;
def FU_FLOAT           : FuncUnit;
def FU_MEMORY          : FuncUnit;

def II_INT             : InstrItinClass;
def II_FLOAT           : InstrItinClass;
def II_MEMORY          : InstrItinClass;
def II_BRANCH          : InstrItinClass;
def II_PSEUDO          : InstrItinClass;

def NyuziItineraries : ProcessorItineraries<[FU_INT, FU_FLOAT, FU_MEMORY], [], [
  InstrItinData<II_INT, [InstrStage<1,  [FU_INT]>], [3, 1], [], 1>,
  InstrItinData<II_BRANCH, [InstrStage<1,  [FU_INT]>], [3, 1], [], 1>,
  InstrItinData<II_FLOAT, [InstrStage<1,  [FU_FLOAT]>], [7, 1], [], 1>,
  InstrItinData<II_MEMORY, [InstrStage<1,  [FU_MEMORY]>], [4, 1], [], 1>,
  InstrItinData<II_PSEUDO, [InstrStage<1, [FU_INT]>]>
]>;
