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

//===----------------------------------------------------------------------===//
// VECTORPROC v8 32-bit.
//===----------------------------------------------------------------------===//

def CC_VectorProc32 : CallingConv<[
  //Custom assign SRet to [sp+64].
  CCIfSRet<CCCustom<"CC_VectorProc_Assign_SRet">>,
  // i32 f32 arguments get passed in integer registers if there is space.
  CCIfType<[i32, f32], CCAssignToReg<[I0, I1, I2, I3, I4, I5]>>,
  // f64 arguments are split and passed through registers or through stack.
  CCIfType<[f64], CCCustom<"CC_VectorProc_Assign_f64">>,

  // Alternatively, they are assigned to the stack in 4-byte aligned units.
  CCAssignToStack<4, 4>
]>;

def RetCC_VectorProc32 : CallingConv<[
  CCIfType<[i32], CCAssignToReg<[I0, I1, I2, I3, I4, I5]>>,
  CCIfType<[f32], CCAssignToReg<[F0, F1, F2, F3]>>,
  CCIfType<[f64], CCAssignToReg<[D0, D1]>>
]>;

