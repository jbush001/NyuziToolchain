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

// Floating-point registers
def F0  : VectorProcReg<"F0", [G0]>, DwarfRegNum<[32]>;
def F1  : VectorProcReg<"F1", [G1]>, DwarfRegNum<[33]>;
def F2  : VectorProcReg<"F2", [G2]>, DwarfRegNum<[34]>; 
def F3  : VectorProcReg<"F3", [G3]>, DwarfRegNum<[35]>;
def F4  : VectorProcReg<"F4", [G4]>, DwarfRegNum<[36]>;
def F5  : VectorProcReg<"F5", [G5]>, DwarfRegNum<[37]>; 
def F6  : VectorProcReg<"F6", [G6]>, DwarfRegNum<[38]>;
def F7  : VectorProcReg<"F7", [G7]>, DwarfRegNum<[39]>;
def F8  : VectorProcReg<"F8", [O0]>, DwarfRegNum<[40]>; 
def F9  : VectorProcReg<"F9", [O1]>, DwarfRegNum<[41]>;
def F10 : VectorProcReg<"F10", [O2]>, DwarfRegNum<[42]>;
def F11 : VectorProcReg<"F11", [O3]>, DwarfRegNum<[43]>; 
def F12 : VectorProcReg<"F12", [O4]>, DwarfRegNum<[44]>;
def F13 : VectorProcReg<"F13", [O5]>, DwarfRegNum<[45]>;
def F14 : VectorProcReg<"F14", [O6]>, DwarfRegNum<[46]>; 
def F15 : VectorProcReg<"F15", [O7]>, DwarfRegNum<[47]>;
def F16 : VectorProcReg<"F16", [L0]>, DwarfRegNum<[48]>;
def F17 : VectorProcReg<"F17", [L1]>, DwarfRegNum<[49]>; 
def F18 : VectorProcReg<"F18", [L2]>, DwarfRegNum<[50]>;
def F19 : VectorProcReg<"F19", [L3]>, DwarfRegNum<[51]>;
def F20 : VectorProcReg<"F20", [L4]>, DwarfRegNum<[52]>; 
def F21 : VectorProcReg<"F21", [L5]>, DwarfRegNum<[53]>;
def F22 : VectorProcReg<"F22", [L6]>, DwarfRegNum<[54]>;
def F23 : VectorProcReg<"F23", [L7]>, DwarfRegNum<[55]>;
def F24 : VectorProcReg<"F24", [I0]>, DwarfRegNum<[56]>;
def F25 : VectorProcReg<"F25", [I1]>, DwarfRegNum<[57]>;
def F26 : VectorProcReg<"F26", [I2]>, DwarfRegNum<[58]>; 
def F27 : VectorProcReg<"F27", [I3]>, DwarfRegNum<[59]>;
def F28 : VectorProcReg<"F28", [I4]>, DwarfRegNum<[60]>;
def F29 : VectorProcReg<"F29", [I5]>, DwarfRegNum<[61]>; 
def F30 : VectorProcReg<"F30", [I6]>, DwarfRegNum<[62]>;
def F31 : VectorProcReg<"F31", [I7]>, DwarfRegNum<[63]>;

// Register classes.
//
// FIXME: the register order should be defined in terms of the preferred
// allocation order...
//
// This register class should not be used to hold i64 values, use the I64Regs
// register class for that. The i64 type is included here to allow i64 patterns
// using the integer instructions.
def IntRegs : RegisterClass<"SP", [i32], 32,
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

// Floating point register classes.
def FPRegs : RegisterClass<"SP", [f32], 32, (sequence "F%u", 0, 31)>;
