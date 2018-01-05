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

  def GP_REG : NyuziReg<"gp", 28>, DwarfRegNum<[28]>;
  def FP_REG : NyuziReg<"fp", 29>, DwarfRegNum<[29]>;
  def SP_REG : NyuziReg<"sp", 30>, DwarfRegNum<[30]>;
  def RA_REG : NyuziReg<"ra", 31>, DwarfRegNum<[31]>;

  foreach i = 0-31 in {
    def V#i : NyuziReg<"v"#i, i>, DwarfRegNum<[!add(i, 32)]>;
  }
}

def GPR32 : RegisterClass<"Nyuzi", [i32, f32, v16i1], 32,
  (add (sequence "S%u", 0, 27), GP_REG, FP_REG, SP_REG, RA_REG)>;

def VR512 : RegisterClass<"Nyuzi", [v16i32, v16f32], 512, (sequence "V%u", 0, 31)>;

