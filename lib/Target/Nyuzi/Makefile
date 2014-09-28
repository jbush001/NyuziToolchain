##===- lib/Target/Nyuzi/Makefile ---------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMNyuziCodeGen
TARGET = Nyuzi

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = NyuziGenRegisterInfo.inc NyuziGenInstrInfo.inc \
		NyuziGenAsmWriter.inc NyuziGenAsmMatcher.inc  NyuziGenDAGISel.inc \
		NyuziGenSubtargetInfo.inc NyuziGenCallingConv.inc \
		NyuziGenMCCodeEmitter.inc

DIRS = TargetInfo MCTargetDesc AsmParser InstPrinter Disassembler

include $(LEVEL)/Makefile.common

