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

#include "llvm/Support/DataTypes.h"

namespace llvm {
class Target;
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class raw_ostream;
class StringRef;

extern Target TheVectorProcTarget;

MCCodeEmitter *createVectorProcMCCodeEmitter(const MCInstrInfo &MCII,
    const MCRegisterInfo &MRI,
    const MCSubtargetInfo &STI,
    MCContext &Ctx);

MCObjectWriter *createVectorProcELFObjectWriter(raw_ostream &OS,
    uint8_t OSABI);

MCAsmBackend *createVectorProcAsmBackend(const Target &T,
    const MCRegisterInfo &MRI,
    StringRef TT,
    StringRef CPU);

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
