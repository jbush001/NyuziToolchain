##===- lib/Target/VectorProc/Makefile ---------------------------*- Makefile -*-===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is distributed under the University of Illinois Open Source
# License. See LICENSE.TXT for details.
#
##===----------------------------------------------------------------------===##

LEVEL = ../../..
LIBRARYNAME = LLVMVectorProcCodeGen
TARGET = VectorProc

# Make sure that tblgen is run, first thing.
BUILT_SOURCES = VectorProcGenRegisterInfo.inc VectorProcGenInstrInfo.inc \
		VectorProcGenAsmWriter.inc VectorProcGenDAGISel.inc \
		VectorProcGenSubtargetInfo.inc VectorProcGenCallingConv.inc

DIRS = TargetInfo MCTargetDesc

include $(LEVEL)/Makefile.common

