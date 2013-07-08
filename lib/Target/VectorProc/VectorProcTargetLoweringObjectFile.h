//===-- VectorProcTargetLoweringObjectFile.cpp - VectorProc Target Lowering Object File ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Used to write out object file
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROC_TARGETLOWERINGOBJECTFILE_H
#define VECTORPROC_TARGETLOWERINGOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {
	class MCSection;

class VectorProcTargetLoweringObjectFile : public TargetLoweringObjectFileELF
{
public:
	virtual const MCSection *getSectionForConstant(SectionKind Kind) const 
	{
		return TextSection;
	};
};

} // end namespace llvm

#endif

