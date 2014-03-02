//===-- VectorProcISelLowering.h - VectorProc DAG Lowering Interface ------*-
//C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that VectorProc uses to lower LLVM code into
// a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#ifndef VECTORPROC_ISELLOWERING_H
#define VECTORPROC_ISELLOWERING_H

#include "VectorProc.h"
#include "llvm/Target/TargetLowering.h"

namespace llvm {
class VectorProcSubtarget;

namespace VectorProcISD {
enum {
  FIRST_NUMBER = ISD::BUILTIN_OP_END,
  CALL,     // A call instruction.
  RET_FLAG, // Return with a flag operand.
  SPLAT,    // Copy scalar register into all lanes of a vector
  SEL_COND_RESULT,
  RECIPROCAL_EST,
  BR_JT,
  JT_WRAPPER
};
}

class VectorProcTargetLowering : public TargetLowering {
  const VectorProcSubtarget *Subtarget;

public:
  VectorProcTargetLowering(TargetMachine &TM);
  virtual SDValue LowerOperation(SDValue Op, SelectionDAG &DAG) const override;
  virtual MachineBasicBlock *EmitInstrWithCustomInserter(MachineInstr *MI, 
  	MachineBasicBlock *MBB) const override;
  virtual const char *getTargetNodeName(unsigned Opcode) const override;
  virtual ConstraintType getConstraintType(const std::string &Constraint) const override;
  virtual std::pair<unsigned, const TargetRegisterClass *>
	  getRegForInlineAsmConstraint(const std::string &Constraint, MVT VT) const override;
  virtual bool isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const override;
  virtual EVT getSetCCResultType(LLVMContext &Context, EVT VT) const override;
  virtual SDValue LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                              bool isVarArg,
                              const SmallVectorImpl<ISD::OutputArg> &Outs,
                              const SmallVectorImpl<SDValue> &OutVals, SDLoc,
                              SelectionDAG &DAG) const override;
  virtual SDValue LowerFormalArguments(SDValue Chain, CallingConv::ID CallConv, 
  									   bool isVarArg,
				                       const SmallVectorImpl<ISD::InputArg> &Ins, SDLoc,
				                       SelectionDAG &DAG,
				                       SmallVectorImpl<SDValue> &InVals) const override;
  virtual SDValue LowerCall(TargetLowering::CallLoweringInfo &CLI,
                            SmallVectorImpl<SDValue> &InVals) const override;
  virtual unsigned getJumpTableEncoding() const override;
  virtual bool isShuffleMaskLegal(const SmallVectorImpl<int> &M, EVT VT) const override;

private:
  MachineBasicBlock *EmitSelectCC(MachineInstr *MI,
                                  MachineBasicBlock *BB) const;
  MachineBasicBlock *EmitAtomicBinary(MachineInstr *MI, MachineBasicBlock *BB,
                                   unsigned Opcode) const;
  MachineBasicBlock *EmitAtomicCmpSwap(MachineInstr *MI,
                                       MachineBasicBlock *BB) const;

  SDValue LowerBUILD_VECTOR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerJumpTable(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerVECTOR_SHUFFLE(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerINSERT_VECTOR_ELT(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerConstantPool(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerConstant(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerFDIV(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBR_JT(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBRIND(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSCALAR_TO_VECTOR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerFNEG(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerEXTRACT_VECTOR_ELT(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSETCC(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerCTLZ_ZERO_UNDEF(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerCTTZ_ZERO_UNDEF(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerUINT_TO_FP(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerSIGN_EXTEND_INREG(SDValue Op, SelectionDAG &DAG) const;
  SDValue LowerBlockAddress(SDValue Op, SelectionDAG &DAG) const;
};
} // end namespace llvm

#endif // VECTORPROC_ISELLOWERING_H
