//===- IntrinsicsVectorProc.td - Defines VectorProc intrinsics ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the VectorProc-specific intrinsics.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

let TargetPrefix = "vectorproc" in {  // All intrinsics start with "llvm.vectorproc.".

def int_vp_get_current_strand : Intrinsic<[llvm_i32_ty], [], [IntrNoMem],
	"llvm.vectorproc.__builtin_vp_get_current_strand">;
}

