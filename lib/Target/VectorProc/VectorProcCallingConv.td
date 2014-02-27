//===-- VectorProcCallingConv.td - Calling Conventions VectorProc ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This describes the calling conventions for the VectorProc architectures.
//
//===----------------------------------------------------------------------===//

def CC_VectorProc32 : CallingConv<[
	CCIfType<[i8, i16], CCPromoteToType<i32>>,

	// i32 f32 arguments get passed in integer registers if there is space.
	CCIfNotVarArg<CCIfType<[i32, f32], CCAssignToReg<[S0, S1, S2, S3, S4, S5, S6, S7]>>>,

	// Vector arguments can be passed in their own registers, as above
	CCIfNotVarArg<CCIfType<[v16i32, v16f32], CCAssignToReg<[V0, V1, V2, V3, V4, V5, V6, V7]>>>,

	// Stick remaining registers onto stack, aligned by size
	CCIfType<[i32, f32], CCAssignToStack<4, 4>>,
	CCIfType<[v16i32, v16f32], CCAssignToStack<64, 64>>
]>;

def RetCC_VectorProc32 : CallingConv<[
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  CCIfType<[i32, f32], CCAssignToReg<[S0, S1, S2, S3, S4, S5]>>,
  
  CCIfType<[v16i32, v16f32], CCAssignToReg<[V0, V1, V2, V3, V4, V5]>>
]>;

def VectorProcCSR : CalleeSavedRegs<(add (sequence "S%u", 24, 27), FP_REG, LINK_REG,
                                   (sequence "V%u", 26, 31))>;

