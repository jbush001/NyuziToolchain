//===-- VectorProcMCTargetDesc.h - VectorProc Target Descriptions ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides VectorProc specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROCMCTARGETDESC_H
#define VECTORPROCMCTARGETDESC_H

namespace llvm {
class Target;

extern Target TheVectorProcTarget;
extern Target TheVectorProcV9Target;

} // End llvm namespace

// Defines symbolic names for VectorProc registers.  This defines a mapping from
// register name to register number.
//
#define GET_REGINFO_ENUM
#include "VectorProcGenRegisterInfo.inc"

// Defines symbolic names for the VectorProc instructions.
//
#define GET_INSTRINFO_ENUM
#include "VectorProcGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "VectorProcGenSubtargetInfo.inc"

#endif
