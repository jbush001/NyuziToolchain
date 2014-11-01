//===-- NyuziRegisterInfo.td - Nyuzi Register defs ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the Nyuzi register file 
//===----------------------------------------------------------------------===//

let Namespace = "Nyuzi" in {
	class NyuziReg<string n, bits<16> number> : Register<n> {
		field bits<16> HWEncoding = number;
	}

	foreach i = 0-27 in {
		def S#i : NyuziReg<"s"#i, i>, DwarfRegNum<[i]>;
	}

	def FP_REG : NyuziReg<"fp", 28>, DwarfRegNum<[28]>;
	def SP_REG : NyuziReg<"sp", 29>, DwarfRegNum<[29]>;
	def RA_REG : NyuziReg<"ra", 30>, DwarfRegNum<[30]>;
	def PC_REG : NyuziReg<"pc", 31>, DwarfRegNum<[31]>;

	foreach i = 0-31 in {
		def V#i : NyuziReg<"v"#i, i>, DwarfRegNum<[!add(i, 32)]>;
	}
}

def GPR32 : RegisterClass<"Nyuzi", [i32, f32], 32, (add (sequence "S%u", 0, 27),
	FP_REG, SP_REG, RA_REG, PC_REG)>;

def VR512 : RegisterClass<"Nyuzi", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

