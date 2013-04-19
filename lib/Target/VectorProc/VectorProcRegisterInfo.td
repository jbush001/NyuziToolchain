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
def G0 : VectorProcReg<"0", []>, DwarfRegNum<[0]>;
def G1 : VectorProcReg<"1", []>, DwarfRegNum<[1]>;
def G2 : VectorProcReg<"2", []>, DwarfRegNum<[2]>; 
def G3 : VectorProcReg<"3", []>, DwarfRegNum<[3]>;
def G4 : VectorProcReg<"4", []>, DwarfRegNum<[4]>;
def G5 : VectorProcReg<"5", []>, DwarfRegNum<[5]>; 
def G6 : VectorProcReg<"6", []>, DwarfRegNum<[6]>;
def G7 : VectorProcReg<"7", []>, DwarfRegNum<[7]>;
def O0 : VectorProcReg<"8", []>, DwarfRegNum<[8]>;
def O1 : VectorProcReg<"9", []>, DwarfRegNum<[9]>;
def O2 : VectorProcReg<"10", []>, DwarfRegNum<[10]>; 
def O3 : VectorProcReg<"11", []>, DwarfRegNum<[11]>;
def O4 : VectorProcReg<"12", []>, DwarfRegNum<[12]>;
def O5 : VectorProcReg<"13", []>, DwarfRegNum<[13]>; 
def O6 : VectorProcReg<"14", []>, DwarfRegNum<[14]>;
def O7 : VectorProcReg<"15", []>, DwarfRegNum<[15]>;
def L0 : VectorProcReg<"16", []>, DwarfRegNum<[16]>;
def L1 : VectorProcReg<"17", []>, DwarfRegNum<[17]>;
def L2 : VectorProcReg<"18", []>, DwarfRegNum<[18]>; 
def L3 : VectorProcReg<"19", []>, DwarfRegNum<[19]>;
def L4 : VectorProcReg<"20", []>, DwarfRegNum<[20]>;
def L5 : VectorProcReg<"21", []>, DwarfRegNum<[21]>; 
def L6 : VectorProcReg<"22", []>, DwarfRegNum<[22]>;
def L7 : VectorProcReg<"23", []>, DwarfRegNum<[23]>;
def I0 : VectorProcReg<"24", []>, DwarfRegNum<[24]>;
def I1 : VectorProcReg<"25", []>, DwarfRegNum<[25]>;
def I2 : VectorProcReg<"26", []>, DwarfRegNum<[26]>; 
def I3 : VectorProcReg<"27", []>, DwarfRegNum<[27]>;
def I4 : VectorProcReg<"28", []>, DwarfRegNum<[28]>;
def I5 : VectorProcReg<"29", []>, DwarfRegNum<[29]>; 
def I6 : VectorProcReg<"30", []>, DwarfRegNum<[30]>;
def I7 : VectorProcReg<"31", []>, DwarfRegNum<[31]>;

// Register classes.
//
// FIXME: the register order should be defined in terms of the preferred
// allocation order...
//
// This register class should not be used to hold i64 values, use the I64Regs
// register class for that. The i64 type is included here to allow i64 patterns
// using the integer instructions.
def IntRegs : RegisterClass<"SP", [i32, f32], 32,
                            (add L0, L1, L2, L3, L4, L5, L6,
                                 L7, I0, I1, I2, I3, I4, I5,
                                 O0, O1, O2, O3, O4, O5, O7,
                                 G1,
                                 // Non-allocatable regs:
                                 G2, G3, G4, // FIXME: OK for use only in
                                             // applications, not libraries.
                                 O6, // stack ptr
                                 I6, // frame ptr
                                 I7, // return address
                                 G0, // constant zero
                                 G5, G6, G7 // reserved for kernel
                                 )>;

