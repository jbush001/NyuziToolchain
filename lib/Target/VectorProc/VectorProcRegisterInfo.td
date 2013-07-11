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
	class VectorProcReg<string n, bits<16> number> : Register<n> {
		field bits<16> HWEncoding = number;
	}

	foreach i = 0-28 in {
		def S#i : VectorProcReg<"s"#i, i>;
	}

	def FP_REG : VectorProcReg<"fp", 28>;
	def SP_REG : VectorProcReg<"sp", 29>;
	def LINK_REG : VectorProcReg<"link", 30>;
	def PC_REG : VectorProcReg<"pc", 31>;

	foreach i = 0-31 in {
		def V#i : VectorProcReg<"v"#i, i>;
	}
}

def ScalarReg : RegisterClass<"VectorProc", [v16i1, i32, f32], 32, (add (sequence "S%u", 0, 27),
	FP_REG, SP_REG, LINK_REG, PC_REG)>;
def VectorReg : RegisterClass<"VectorProc", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

