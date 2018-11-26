//===-- NyuziMCTargetDesc.h - Nyuzi Target Descriptions ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides Nyuzi specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_NYUZIMCTARGETDESC_H
#define LLVM_LIB_TARGET_NYUZI_NYUZIMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
class Target;
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectTargetWriter;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class MCTargetOptions;
class raw_ostream;
class StringRef;
class Triple;

extern Target TheNyuziTarget;

MCCodeEmitter *createNyuziMCCodeEmitter(const MCInstrInfo &MCII,
                                        const MCRegisterInfo &MRI,
                                        MCContext &Ctx);

std::unique_ptr<MCObjectTargetWriter> createNyuziELFObjectWriter(uint8_t OSABI);

MCAsmBackend *createNyuziAsmBackend(const Target &T,
                                    const MCSubtargetInfo &STI,
                                    const MCRegisterInfo &MRI,
                                    const MCTargetOptions &Options);

} // namespace llvm

// Defines symbolic names for Nyuzi registers.  This defines a mapping from
// register name to register number.
//
#define GET_REGINFO_ENUM
#include "NyuziGenRegisterInfo.inc"

// Defines symbolic names for the Nyuzi instructions.
//
#define GET_INSTRINFO_ENUM
#include "NyuziGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "NyuziGenSubtargetInfo.inc"

#endif
