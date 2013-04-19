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

class VectorProcCtrlReg<string n>: Register<n> {
  let Namespace = "SP";
}

// Control Registers
def ICC : VectorProcCtrlReg<"ICC">; // This represents icc and xcc in 64-bit code.
def FCC : VectorProcCtrlReg<"FCC">;

// Y register
def Y : VectorProcCtrlReg<"Y">;

// Integer registers
def S0 : VectorProcReg<"0", []>, DwarfRegNum<[0]>;
def S1 : VectorProcReg<"1", []>, DwarfRegNum<[1]>;
def S2 : VectorProcReg<"2", []>, DwarfRegNum<[2]>; 
def S3 : VectorProcReg<"3", []>, DwarfRegNum<[3]>;
def S4 : VectorProcReg<"4", []>, DwarfRegNum<[4]>;
def S5 : VectorProcReg<"5", []>, DwarfRegNum<[5]>; 
def S6 : VectorProcReg<"6", []>, DwarfRegNum<[6]>;
def S7 : VectorProcReg<"7", []>, DwarfRegNum<[7]>;
def S8 : VectorProcReg<"8", []>, DwarfRegNum<[8]>;
def S9 : VectorProcReg<"9", []>, DwarfRegNum<[9]>;
def S10 : VectorProcReg<"10", []>, DwarfRegNum<[10]>; 
def S11 : VectorProcReg<"11", []>, DwarfRegNum<[11]>;
def S12 : VectorProcReg<"12", []>, DwarfRegNum<[12]>;
def S13 : VectorProcReg<"13", []>, DwarfRegNum<[13]>; 
def S14 : VectorProcReg<"14", []>, DwarfRegNum<[14]>;
def S15 : VectorProcReg<"15", []>, DwarfRegNum<[15]>;
def S16 : VectorProcReg<"16", []>, DwarfRegNum<[16]>;
def S17 : VectorProcReg<"17", []>, DwarfRegNum<[17]>;
def S18 : VectorProcReg<"18", []>, DwarfRegNum<[18]>; 
def S19 : VectorProcReg<"19", []>, DwarfRegNum<[19]>;
def S20 : VectorProcReg<"20", []>, DwarfRegNum<[20]>;
def S21 : VectorProcReg<"21", []>, DwarfRegNum<[21]>; 
def S22 : VectorProcReg<"22", []>, DwarfRegNum<[22]>;
def S23 : VectorProcReg<"23", []>, DwarfRegNum<[23]>;
def S24 : VectorProcReg<"24", []>, DwarfRegNum<[24]>;
def S25 : VectorProcReg<"25", []>, DwarfRegNum<[25]>;
def S26 : VectorProcReg<"26", []>, DwarfRegNum<[26]>; 
def S27 : VectorProcReg<"27", []>, DwarfRegNum<[27]>;
def S28 : VectorProcReg<"28", []>, DwarfRegNum<[28]>;
def S29 : VectorProcReg<"29", []>, DwarfRegNum<[29]>; 
def S30 : VectorProcReg<"30", []>, DwarfRegNum<[30]>;
def S31 : VectorProcReg<"31", []>, DwarfRegNum<[31]>;

def ScalarRegs : RegisterClass<"SP", [i32, f32], 32, (sequence "S%u", 0, 31)>;
