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

class VectorProcReg<string n, list<Register> aliases> : Register<n> {
  let Namespace = "SP";
  let Aliases = aliases;
}

foreach i = 0-31 in {
	def S#i : VectorProcReg<""#i, []>;
}

def ScalarReg : RegisterClass<"SP", [i32, f32], 32, (sequence "S%u", 0, 31)>;

