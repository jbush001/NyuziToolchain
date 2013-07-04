//===-- VectorProcRegisterInfo.td - VectorProc Register defs ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the VectorProc register file 
//===----------------------------------------------------------------------===//

class VectorProcReg<string n> : Register<n> {
  let Namespace = "SP";
}

foreach i = 0-28 in {
	def S#i : VectorProcReg<""#i>;
}

def FP_REG : VectorProcReg<"28">;
def SP_REG : VectorProcReg<"29">;
def LINK_REG : VectorProcReg<"30">;
def PC_REG : VectorProcReg<"31">;

foreach i = 0-31 in {
	def V#i : VectorProcReg<""#i>;
}

def ScalarReg : RegisterClass<"SP", [v16i1, i32, f32], 32, (add (sequence "S%u", 0, 27),
	FP_REG, SP_REG, LINK_REG, PC_REG)>;
def VectorReg : RegisterClass<"SP", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

