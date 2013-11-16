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

	foreach i = 0-27 in {
		def S#i : VectorProcReg<"s"#i, i>, DwarfRegNum<[i]>;
	}

	def FP_REG : VectorProcReg<"fp", 28>, DwarfRegNum<[28]>;
	def SP_REG : VectorProcReg<"sp", 29>, DwarfRegNum<[29]>;
	def LINK_REG : VectorProcReg<"link", 30>, DwarfRegNum<[30]>;
	def PC_REG : VectorProcReg<"pc", 31>, DwarfRegNum<[31]>;

	foreach i = 0-31 in {
		def V#i : VectorProcReg<"v"#i, i>, DwarfRegNum<[!add(i, 32)]>;
	}
}

def ScalarReg : RegisterClass<"VectorProc", [i32, f32], 32, (add (sequence "S%u", 0, 27),
	FP_REG, SP_REG, LINK_REG, PC_REG)>;

def VectorReg : RegisterClass<"VectorProc", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

