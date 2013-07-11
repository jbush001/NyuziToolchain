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

let Namespace = "VectorProc" in {
	class VectorProcReg<string n> : Register<n>;

	foreach i = 0-28 in {
		def S#i : VectorProcReg<"s"#i>;
	}

	def FP_REG : VectorProcReg<"fp">;
	def SP_REG : VectorProcReg<"sp">;
	def LINK_REG : VectorProcReg<"link">;
	def PC_REG : VectorProcReg<"pc">;

	foreach i = 0-31 in {
		def V#i : VectorProcReg<"v"#i>;
	}
}

def ScalarReg : RegisterClass<"VectorProc", [v16i1, i32, f32], 32, (add (sequence "S%u", 0, 27),
	FP_REG, SP_REG, LINK_REG, PC_REG)>;
def VectorReg : RegisterClass<"VectorProc", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

