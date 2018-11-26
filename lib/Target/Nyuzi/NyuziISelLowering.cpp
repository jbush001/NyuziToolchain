//===-- NyuziISelLowering.cpp - Nyuzi DAG Lowering Implementation ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the interfaces that Nyuzi uses to lower LLVM code
// into a selection DAG.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "nyuzi-isel-lowering"

#include "NyuziISelLowering.h"
#include "MCTargetDesc/NyuziBaseInfo.h"
#include "MCTargetDesc/NyuziMCTargetDesc.h"
#include "NyuziMachineFunctionInfo.h"
#include "NyuziTargetMachine.h"
#include "NyuziTargetObjectFile.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#include "NyuziGenCallingConv.inc"

namespace {

// isSplatVector - Returns true if N is a BUILD_VECTOR node whose elements are
// all the same.
bool isSplatVector(SDNode *N) {
  SDValue SplatValue = N->getOperand(0);
  for (auto Lane : N->op_values())
    if (Lane != SplatValue)
      return false;

  return true;
}

// Turn a SETCC node into a (possibly different) target-specific float comparison
// node  with the same operands as the SETCC node.
SDValue morphSETCCNode(SDValue Op, NyuziISD::NodeType Compare, SelectionDAG &DAG) {
  SDLoc DL(Op);
  return DAG.getNode(Compare, DL, Op.getValueType().getSimpleVT(),
                     Op.getOperand(0), Op.getOperand(1));
}

} // namespace

NyuziTargetLowering::NyuziTargetLowering(const TargetMachine &TM,
                                         const NyuziSubtarget &STI)
    : TargetLowering(TM), Subtarget(STI) {

  // Set up the register classes.
  addRegisterClass(MVT::i32, &Nyuzi::GPR32RegClass);
  addRegisterClass(MVT::v16i1, &Nyuzi::GPR32RegClass);
  addRegisterClass(MVT::f32, &Nyuzi::GPR32RegClass);
  addRegisterClass(MVT::v16i32, &Nyuzi::VR512RegClass);
  addRegisterClass(MVT::v16f32, &Nyuzi::VR512RegClass);

  for (MVT VT : MVT::integer_valuetypes())
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i1, Promote);

  struct {
    ISD::NodeType Operation;
    MVT Type;
  } CustomActions[] = {
    { ISD::BUILD_VECTOR, MVT::v16f32 },
    { ISD::BUILD_VECTOR, MVT::v16i32 },
    { ISD::BUILD_VECTOR, MVT::v16i1 },
    { ISD::INSERT_VECTOR_ELT, MVT::v16f32 },
    { ISD::INSERT_VECTOR_ELT, MVT::v16i32 },
    { ISD::INSERT_VECTOR_ELT, MVT::v16i1 },
    { ISD::EXTRACT_VECTOR_ELT, MVT::v16i1 },
    { ISD::VECTOR_SHUFFLE, MVT::v16i32 },
    { ISD::VECTOR_SHUFFLE, MVT::v16f32 },
    { ISD::VECTOR_SHUFFLE, MVT::v16i1 },
    { ISD::SCALAR_TO_VECTOR, MVT::v16i32 },
    { ISD::SCALAR_TO_VECTOR, MVT::v16f32 },
    { ISD::SCALAR_TO_VECTOR, MVT::v16i1 },
    { ISD::GlobalAddress, MVT::i32 },
    { ISD::GlobalAddress, MVT::f32 },
    { ISD::ConstantPool, MVT::i32 },
    { ISD::ConstantPool, MVT::v16i32 },
    { ISD::ConstantPool, MVT::f32 },
    { ISD::BlockAddress, MVT::i32 },
    { ISD::SELECT_CC, MVT::i32 },
    { ISD::SELECT_CC, MVT::f32 },
    { ISD::SELECT_CC, MVT::v16i1 },
    { ISD::SELECT_CC, MVT::v16i32 },
    { ISD::SELECT_CC, MVT::v16f32 },
    { ISD::SELECT, MVT::v16i1 },
    { ISD::VSELECT, MVT::v16i1},
    { ISD::FDIV, MVT::f32 },
    { ISD::FDIV, MVT::v16f32 },
    { ISD::FNEG, MVT::f32 },
    { ISD::FNEG, MVT::v16f32 },
    { ISD::SETCC, MVT::v16f32 },
    { ISD::SETCC, MVT::f32 },
    { ISD::SETCC, MVT::v16i1 },
    { ISD::CTLZ_ZERO_UNDEF, MVT::i32 },
    { ISD::CTTZ_ZERO_UNDEF, MVT::i32 },
    { ISD::UINT_TO_FP, MVT::v16i1 },
    { ISD::SINT_TO_FP, MVT::v16i1 },
    { ISD::FP_TO_SINT, MVT::v16i1 },
    { ISD::FP_TO_UINT, MVT::v16i1 },
    { ISD::FRAMEADDR, MVT::i32 },
    { ISD::RETURNADDR, MVT::i32 },
    { ISD::VASTART, MVT::Other },
    { ISD::FABS, MVT::f32 },
    { ISD::FABS, MVT::v16f32 },
    { ISD::TRUNCATE, MVT::v16i1 },
    { ISD::ZERO_EXTEND, MVT::v16i32 },
    { ISD::SIGN_EXTEND, MVT::v16i32 },
    { ISD::JumpTable, MVT::i32 }
  };

  for (auto Action : CustomActions)
    setOperationAction(Action.Operation, Action.Type, Custom);

  struct {
    ISD::NodeType Operation;
    MVT Type;
  } ExpandActions[] = {
    { ISD::BR_CC, MVT::i32 },
    { ISD::BR_CC, MVT::f32 },
    { ISD::BR_CC, MVT::v16i32 },
    { ISD::BR_CC, MVT::v16f32 },
    { ISD::BR_CC, MVT::v16i1 },
    { ISD::BRCOND, MVT::i32 },
    { ISD::BRCOND, MVT::f32 },
    { ISD::SIGN_EXTEND_INREG, MVT::i1 },
    { ISD::CTPOP, MVT::i32 },
    { ISD::SELECT, MVT::i32 },
    { ISD::SELECT, MVT::v16i32 },
    { ISD::SELECT, MVT::f32 },
    { ISD::SELECT, MVT::v16f32 },
    { ISD::ROTL, MVT::i32 },
    { ISD::ROTR, MVT::i32 },
    { ISD::ROTL, MVT::v16i32 },
    { ISD::ROTR, MVT::v16i32 },
    { ISD::UDIVREM, MVT::i32 },
    { ISD::SDIVREM, MVT::i32 },
    { ISD::UMUL_LOHI, MVT::i32 },
    { ISD::SMUL_LOHI, MVT::i32 },
    { ISD::FP_TO_UINT, MVT::i32 },
    { ISD::FP_TO_UINT, MVT::v16i32 },
    { ISD::DYNAMIC_STACKALLOC, MVT::i32 },
    { ISD::STACKSAVE, MVT::Other },
    { ISD::STACKRESTORE, MVT::Other },
    { ISD::BSWAP, MVT::i32 },
    { ISD::ADDC, MVT::i32 },
    { ISD::ADDE, MVT::i32 },
    { ISD::SUBC, MVT::i32 },
    { ISD::SUBE, MVT::i32 },
    { ISD::SRA_PARTS, MVT::i32 },
    { ISD::SRL_PARTS, MVT::i32 },
    { ISD::SHL_PARTS, MVT::i32 },
    { ISD::VAARG, MVT::Other },
    { ISD::VACOPY, MVT::Other },
    { ISD::VAEND, MVT::Other },
    { ISD::ATOMIC_LOAD, MVT::i32 },
    { ISD::ATOMIC_LOAD, MVT::i64 },
    { ISD::ATOMIC_STORE, MVT::i32 },
    { ISD::ATOMIC_STORE, MVT::i64 },
    { ISD::FCOPYSIGN, MVT::f32 },
    { ISD::FCEIL, MVT::f32 },
    { ISD::FCEIL, MVT::v16f32 },
    { ISD::FTRUNC, MVT::f32 },
    { ISD::FTRUNC, MVT::v16f32 },
    { ISD::FRINT, MVT::f32 },
    { ISD::FRINT, MVT::v16f32 },
    { ISD::FNEARBYINT, MVT::f32 },
    { ISD::FNEARBYINT, MVT::v16f32 },
    { ISD::FROUND, MVT::f32 },
    { ISD::FROUND, MVT::v16f32 },
    { ISD::FFLOOR, MVT::f32 },
    { ISD::FFLOOR, MVT::v16f32 },
    { ISD::BR_JT, MVT::Other },
    { ISD::UINT_TO_FP, MVT::i32 },
    { ISD::UINT_TO_FP, MVT::v16i32 }
  };

  for (auto Action : ExpandActions)
    setOperationAction(Action.Operation, Action.Type, Expand);

  setOperationAction(ISD::TRAP, MVT::Other, Legal);

  // Compiler will expand these to a series of scalar stores/loads.
  setTruncStoreAction(MVT::v16i32, MVT::v16i16, Expand);
  setTruncStoreAction(MVT::v16i32, MVT::v16i8, Expand);
  for (auto Op : { ISD::ZEXTLOAD, ISD::SEXTLOAD, ISD::EXTLOAD })
    for (auto Type : { MVT::v16i16, MVT::v16i8 })
      setLoadExtAction(Op, MVT::v16i32, Type, Expand);

  // Hardware does not have an integer divider, so convert these to
  // library calls
  ISD::NodeType IntLibCalls[] = {
    ISD::UDIV, // __udivsi3
    ISD::UREM, // __umodsi3
    ISD::SDIV, // __divsi3
    ISD::SREM  // __modsi3
  };

  for (auto Op : IntLibCalls) {
    setOperationAction(Op, MVT::i32, Expand);
    setOperationAction(Op, MVT::v16i32, Expand);
  }

  ISD::NodeType FloatLibCalls[] = {
    ISD::FSQRT, // sqrtf
    ISD::FSIN,  // sinf
    ISD::FCOS,  // cosf
    ISD::FREM,   // remf
    ISD::FSINCOS
  };

  for (auto Op : FloatLibCalls) {
    setOperationAction(Op, MVT::f32, Expand); // sqrtf
    setOperationAction(Op, MVT::v16f32, Expand); // sinf
  }

  setStackPointerRegisterToSaveRestore(Nyuzi::SP_REG);
  setMinFunctionAlignment(2);

  computeRegisterProperties(Subtarget.getRegisterInfo());
}

SDValue NyuziTargetLowering::LowerOperation(SDValue Op,
                                            SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::GlobalAddress:
    return LowerGlobalAddress(Op, DAG);
  case ISD::BUILD_VECTOR:
    return LowerBUILD_VECTOR(Op, DAG);
  case ISD::VECTOR_SHUFFLE:
    return LowerVECTOR_SHUFFLE(Op, DAG);
  case ISD::INSERT_VECTOR_ELT:
    return LowerINSERT_VECTOR_ELT(Op, DAG);
  case ISD::EXTRACT_VECTOR_ELT:
    return LowerEXTRACT_VECTOR_ELT(Op, DAG);
  case ISD::SCALAR_TO_VECTOR:
    return LowerSCALAR_TO_VECTOR(Op, DAG);
  case ISD::SELECT_CC:
    return LowerSELECT_CC(Op, DAG);
  case ISD::SELECT:
    return LowerSELECT(Op, DAG);
  case ISD::VSELECT:
    return LowerVSELECT(Op, DAG);
  case ISD::SETCC:
    return LowerSETCC(Op, DAG);
  case ISD::ConstantPool:
    return LowerConstantPool(Op, DAG);
  case ISD::FDIV:
    return LowerFDIV(Op, DAG);
  case ISD::FNEG:
    return LowerFNEG(Op, DAG);
  case ISD::FABS:
    return LowerFABS(Op, DAG);
  case ISD::BlockAddress:
    return LowerBlockAddress(Op, DAG);
  case ISD::VASTART:
    return LowerVASTART(Op, DAG);
  case ISD::CTLZ_ZERO_UNDEF:
    return LowerCTLZ_ZERO_UNDEF(Op, DAG);
  case ISD::CTTZ_ZERO_UNDEF:
    return LowerCTTZ_ZERO_UNDEF(Op, DAG);
  case ISD::UINT_TO_FP:
    return LowerUINT_TO_FP(Op, DAG);
  case ISD::SINT_TO_FP:
    return LowerSINT_TO_FP(Op, DAG);
  case ISD::FRAMEADDR:
    return LowerFRAMEADDR(Op, DAG);
  case ISD::RETURNADDR:
    return LowerRETURNADDR(Op, DAG);
  case ISD::SIGN_EXTEND:
    return LowerSIGN_EXTEND(Op, DAG);
  case ISD::ZERO_EXTEND:
    return LowerZERO_EXTEND(Op, DAG);
  case ISD::TRUNCATE:
    return LowerTRUNCATE(Op, DAG);
  case ISD::FP_TO_SINT:
  case ISD::FP_TO_UINT:
    return LowerFP_TO_XINT(Op, DAG);
  case ISD::JumpTable:
    return LowerJumpTable(Op, DAG);
  default:
    llvm_unreachable("Should not custom lower this!");
  }
}

SDValue
NyuziTargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                                 bool IsVarArg,
                                 const SmallVectorImpl<ISD::OutputArg> &Outs,
                                 const SmallVectorImpl<SDValue> &OutVals,
                                 const SDLoc &DL, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();

  // CCValAssign - represent the assignment of the return value to locations.
  SmallVector<CCValAssign, 16> RVLocs;

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  // Analyze return values.
  CCInfo.AnalyzeReturn(Outs, RetCC_Nyuzi32);

  SDValue Flag;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");
    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together with flags.
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  if (MF.getFunction().hasStructRetAttr()) {
    NyuziMachineFunctionInfo *VFI = MF.getInfo<NyuziMachineFunctionInfo>();
    unsigned Reg = VFI->getSRetReturnReg();
    if (!Reg)
      llvm_unreachable("sret virtual register not created in the entry block");

    SDValue Val =
        DAG.getCopyFromReg(Chain, DL, Reg, getPointerTy(DAG.getDataLayout()));
    Chain = DAG.getCopyToReg(Chain, DL, Nyuzi::S0, Val, Flag);
    Flag = Chain.getValue(1);
    RetOps.push_back(
        DAG.getRegister(Nyuzi::S0, getPointerTy(DAG.getDataLayout())));
  }

  RetOps[0] = Chain; // Update chain.

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(NyuziISD::RET_FLAG, DL, MVT::Other, RetOps);
}

SDValue NyuziTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  // Analyze operands of the call, assigning locations to each operand.
  // NyuziCallingConv.td will auto-generate CC_Nyuzi32, which
  // knows how to handle operands (what go in registers vs. stack, etc).
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), ArgLocs,
                 *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_Nyuzi32);

  // Walk through each parameter and push into InVals
  int ParamEndOffset = 0;
  for (const auto &VA : ArgLocs) {
    if (VA.isRegLoc()) {
      // Argument is in register
      EVT RegVT = VA.getLocVT();
      const TargetRegisterClass *RC;

      if (RegVT == MVT::i32 || RegVT == MVT::f32 || RegVT == MVT::v16i1)
        RC = &Nyuzi::GPR32RegClass;
      else if (RegVT == MVT::v16i32 || RegVT == MVT::v16f32)
        RC = &Nyuzi::VR512RegClass;
      else
        llvm_unreachable("Unsupported formal argument Type");

      unsigned VReg = RegInfo.createVirtualRegister(RC);
      MF.getRegInfo().addLiveIn(VA.getLocReg(), VReg);
      SDValue Arg = DAG.getCopyFromReg(Chain, DL, VReg, VA.getLocVT());
      InVals.push_back(Arg);
      continue;
    }

    // Otherwise this parameter is on the stack
    assert(VA.isMemLoc());
    int ParamSize = VA.getValVT().getSizeInBits() / 8;
    int ParamOffset = VA.getLocMemOffset();
    int FI = MF.getFrameInfo().CreateFixedObject(ParamSize, ParamOffset, true);
    ParamEndOffset = ParamOffset + ParamSize;

    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy(DAG.getDataLayout()));
    SDValue Load;
    if (VA.getValVT() == MVT::i32 || VA.getValVT() == MVT::f32 ||
        VA.getValVT() == MVT::v16i32 || VA.getValVT() == MVT::v16f32 ||
        VA.getValVT() == MVT::v16i1) {
      // Primitive Types are loaded directly from the stack
      Load = DAG.getLoad(VA.getValVT(), DL, Chain, FIPtr, MachinePointerInfo());
    } else {
      // This is a smaller Type (char, etc).  Sign extend.
      ISD::LoadExtType LoadOp = ISD::SEXTLOAD;
      unsigned Offset = 4 - std::max(1U, VA.getValVT().getSizeInBits() / 8);
      FIPtr = DAG.getNode(ISD::ADD, DL, MVT::i32, FIPtr,
                          DAG.getConstant(Offset, DL, MVT::i32));
      Load = DAG.getExtLoad(LoadOp, DL, MVT::i32, Chain, FIPtr,
                            MachinePointerInfo(), VA.getValVT());
      Load = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), Load);
    }

    InVals.push_back(Load);
  }

  NyuziMachineFunctionInfo *VFI = MF.getInfo<NyuziMachineFunctionInfo>();

  if (isVarArg) {
    // Create a dummy object where the first parameter would start.  This will
    // be used
    // later to determine the start address of variable arguments.
    int FirstVarArg =
        MF.getFrameInfo().CreateFixedObject(4, ParamEndOffset, false);
    VFI->setVarArgsFrameIndex(FirstVarArg);
  }

  if (MF.getFunction().hasStructRetAttr()) {
    // When a function returns a structure, the address of the return value
    // is placed in the first physical register.
    unsigned Reg = VFI->getSRetReturnReg();
    if (!Reg) {
      Reg = MF.getRegInfo().createVirtualRegister(&Nyuzi::GPR32RegClass);
      VFI->setSRetReturnReg(Reg);
    }

    SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), DL, Reg, InVals[0]);
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, Copy, Chain);
  }

  return Chain;
}

// Generate code to call a function
SDValue NyuziTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                       SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &DL = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CallingConv::ID CallConv = CLI.CallConv;
  bool isVarArg = CLI.IsVarArg;

  // We do not support tail calls. This flag must be cleared in order
  // to indicate that to subsequent passes.
  CLI.IsTailCall = false;

  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetFrameLowering *TFL = MF.getSubtarget().getFrameLowering();

  // Analyze operands of the call, assigning locations to each operand.
  // NyuziCallingConv.td will auto-generate CC_Nyuzi32, which knows how to
  // handle operands (what go in registers vs. stack, etc).
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), ArgLocs,
                 *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_Nyuzi32);

  // Get the size of the outgoing arguments stack space requirement.
  // We always keep the stack pointer 64 byte aligned so we can use block
  // loads/stores for vector arguments
  unsigned ArgsSize =
      alignTo(CCInfo.getNextStackOffset(), TFL->getStackAlignment());

  // Create local copies for all arguments that are passed by value
  SmallVector<SDValue, 8> ByValArgs;
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    ISD::ArgFlagsTy Flags = Outs[i].Flags;
    if (!Flags.isByVal())
      continue;

    SDValue Arg = OutVals[i];
    unsigned Size = Flags.getByValSize();
    unsigned Align = Flags.getByValAlign();

    int FI = MFI.CreateStackObject(Size, Align, false);
    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy(DAG.getDataLayout()));
    SDValue SizeNode = DAG.getConstant(Size, DL, MVT::i32);
    Chain = DAG.getMemcpy(Chain, DL, FIPtr, Arg, SizeNode, Align,
                          false,        // isVolatile,
                          (Size <= 32), // AlwaysInline if size <= 32
                          false, MachinePointerInfo(), MachinePointerInfo());

    ByValArgs.push_back(FIPtr);
  }

  // CALLSEQ_START will decrement the stack to reserve space
  Chain = DAG.getCALLSEQ_START(Chain, ArgsSize, 0, DL);

  SmallVector<std::pair<unsigned, SDValue>, 8> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;

  // Walk through arguments, storing each one to the proper palce
  for (unsigned i = 0, realArgIdx = 0, byvalArgIdx = 0, e = ArgLocs.size();
       i != e; ++i, ++realArgIdx) {

    CCValAssign &VA = ArgLocs[i];
    SDValue Arg = OutVals[realArgIdx];

    ISD::ArgFlagsTy Flags = Outs[realArgIdx].Flags;

    // Use the local copy we created above if this is passed by value
    if (Flags.isByVal())
      Arg = ByValArgs[byvalArgIdx++];

    // Promote the value if needed.
    switch (VA.getLocInfo()) {
    case CCValAssign::Full:
      break;

    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, DL, VA.getLocVT(), Arg);
      break;

    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, DL, VA.getLocVT(), Arg);
      break;

    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, DL, VA.getLocVT(), Arg);
      break;

    case CCValAssign::BCvt:
      Arg = DAG.getBitcast(VA.getLocVT(), Arg);
      break;

    default:
      llvm_unreachable("Unknown loc info!");
    }

    // Arguments that can be passed on register must be kept at
    // RegsToPass vector
    if (VA.isRegLoc()) {
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
      continue;
    }

    // This needs to be pushed on the stack
    assert(VA.isMemLoc());

    // Create a store off the stack pointer for this argument.
    SDValue StackPtr = DAG.getRegister(Nyuzi::SP_REG, MVT::i32);
    SDValue PtrOff = DAG.getIntPtrConstant(VA.getLocMemOffset(), DL);
    PtrOff = DAG.getNode(ISD::ADD, DL, MVT::i32, StackPtr, PtrOff);
    MemOpChains.push_back(
        DAG.getStore(Chain, DL, Arg, PtrOff, MachinePointerInfo()));
  }

  // Emit all stores, make sure the occur before any copies into physregs.
  if (!MemOpChains.empty()) {
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);
  }

  // Build a sequence of copy-to-reg nodes chained together with token chain
  // and flag operands which copy the outgoing args into registers. The InFlag
  // in necessary since all emitted instructions must be stuck together.
  SDValue InFlag;
  for (const auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first, Reg.second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // Get the function address.
  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  bool functionInGot = isPositionIndependent();
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    functionInGot &= !G->getGlobal()->hasLocalLinkage();
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), DL, MVT::i32, 0,
      functionInGot ? Nyuzi::MO_GOT : 0);
  } else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i32,
      functionInGot ? Nyuzi::MO_GOT : 0);
  }

  // Need to put in got if this is possibly outside this shared library
  // and PIC mode is enabled.
  if (functionInGot) {
    EVT Ty = getPointerTy(DAG.getDataLayout());
    SDValue GPReg = DAG.getRegister(Nyuzi::GP_REG, MVT::i32);
    SDValue Wrapper = DAG.getNode(NyuziISD::GOT_ADDR, DL, Ty, GPReg,
                              Callee);
    Callee = DAG.getLoad(Ty, DL, DAG.getEntryNode(), Wrapper,
      MachinePointerInfo::getGOT(DAG.getMachineFunction()));
  }

  // Returns a chain & a flag for retval copy to use
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  for (const auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first, Reg.second.getValueType()));

  // Add a register mask operand representing the call-preserved registers.
  const TargetRegisterInfo *TRI = Subtarget.getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(MF, CLI.CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(CLI.DAG.getRegisterMask(Mask));

  if (InFlag.getNode())
    Ops.push_back(InFlag);

  Chain = DAG.getNode(NyuziISD::CALL, DL, NodeTys, Ops);
  InFlag = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(ArgsSize, DL, true),
                             DAG.getIntPtrConstant(0, DL, true), InFlag, DL);
  InFlag = Chain.getValue(1);

  // The call has returned, handle return values
  SmallVector<CCValAssign, 16> RVLocs;
  CCState RVInfo(CallConv, isVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  RVInfo.AnalyzeCallResult(Ins, RetCC_Nyuzi32);

  // Copy all of the result registers out of their specified physreg.
  for (const auto &Loc : RVLocs) {
    Chain =
        DAG.getCopyFromReg(Chain, DL, Loc.getLocReg(), Loc.getValVT(), InFlag)
            .getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

MachineBasicBlock *
NyuziTargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                                 MachineBasicBlock *BB) const {
  switch (MI.getOpcode()) {
  case Nyuzi::SELECTI:
  case Nyuzi::SELECTF:
  case Nyuzi::SELECTVI:
  case Nyuzi::SELECTVF:
  case Nyuzi::SELECTMASK:
    return EmitSelectCC(MI, BB);

  case Nyuzi::ATOMIC_LOAD_ADDR:
    return EmitAtomicBinary(MI, BB, Nyuzi::ADDISSS);

  case Nyuzi::ATOMIC_LOAD_ADDI:
    return EmitAtomicBinary(MI, BB, Nyuzi::ADDISSI);

  case Nyuzi::ATOMIC_LOAD_SUBR:
    return EmitAtomicBinary(MI, BB, Nyuzi::SUBISSS);

  case Nyuzi::ATOMIC_LOAD_NANDR:
    return EmitAtomicBinary(MI, BB, Nyuzi::ANDSSS, true);

  case Nyuzi::ATOMIC_LOAD_SUBI:
    return EmitAtomicBinary(MI, BB, Nyuzi::SUBISSI);

  case Nyuzi::ATOMIC_LOAD_ANDR:
    return EmitAtomicBinary(MI, BB, Nyuzi::ANDSSS);

  case Nyuzi::ATOMIC_LOAD_ANDI:
    return EmitAtomicBinary(MI, BB, Nyuzi::ANDSSI);

  case Nyuzi::ATOMIC_LOAD_ORR:
    return EmitAtomicBinary(MI, BB, Nyuzi::ORSSS);

  case Nyuzi::ATOMIC_LOAD_ORI:
    return EmitAtomicBinary(MI, BB, Nyuzi::ORSSI);

  case Nyuzi::ATOMIC_LOAD_XORR:
    return EmitAtomicBinary(MI, BB, Nyuzi::XORSSS);

  case Nyuzi::ATOMIC_LOAD_XORI:
    return EmitAtomicBinary(MI, BB, Nyuzi::XORSSI);

  case Nyuzi::ATOMIC_LOAD_NANDI:
    return EmitAtomicBinary(MI, BB, Nyuzi::ANDSSI, true);

  case Nyuzi::ATOMIC_SWAP:
    return EmitAtomicBinary(MI, BB, 0);

  case Nyuzi::ATOMIC_CMP_SWAP:
    return EmitAtomicCmpSwap(MI, BB);

  default:
    llvm_unreachable("unknown atomic operation");
  }
}

const char *NyuziTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  case NyuziISD::CALL:
    return "NyuziISD::CALL";
  case NyuziISD::RET_FLAG:
    return "NyuziISD::RET_FLAG";
  case NyuziISD::SPLAT:
    return "NyuziISD::SPLAT";
  case NyuziISD::SEL_COND_RESULT:
    return "NyuziISD::SEL_COND_RESULT";
  case NyuziISD::RECIPROCAL_EST:
    return "NyuziISD::RECIPROCAL_EST";
  case NyuziISD::MASK_TO_INT:
    return "NyuziISD::MASK_TO_INT";
  case NyuziISD::MASK_FROM_INT:
    return "NyuziISD::MASK_FROM_INT";
  case NyuziISD::MOVEHI:
    return "NyuziISD::MOVEHI";
  case NyuziISD::ORLO:
    return "NyuziISD::ORLO";
  case NyuziISD::GOT_ADDR:
    return "NyuziISD::GOT_ADDR";
  case NyuziISD::FGT:
    return "NyuziISD::FGT";
  case NyuziISD::FGE:
    return "NyuziISD::FGE";
  case NyuziISD::FLT:
    return "NyuziISD::FLT";
  case NyuziISD::FLE:
    return "NyuziISD::FLE";
  case NyuziISD::FEQ:
    return "NyuziISD::FEQ";
  case NyuziISD::FNE:
    return "NyuziISD::FNE";
  default:
    return nullptr;
  }
}

/// getConstraintType - Given a constraint letter, return the Type of
/// constraint it is for this target.
NyuziTargetLowering::ConstraintType
NyuziTargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 's':
    case 'r':
    case 'v':
      return C_RegisterClass;
    default:
      break;
    }
  }

  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
NyuziTargetLowering::getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                                                  StringRef Constraint,
                                                  MVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 's':
    case 'r':
      return std::make_pair(0U, &Nyuzi::GPR32RegClass);

    case 'v':
      return std::make_pair(0U, &Nyuzi::VR512RegClass);
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}

bool NyuziTargetLowering::isOffsetFoldingLegal(
    const GlobalAddressSDNode *GA) const {
  // The Nyuzi target isn't yet aware of offsets.
  return false;
}

EVT NyuziTargetLowering::getSetCCResultType(const DataLayout &,
                                            LLVMContext &Context,
                                            EVT VT) const {
  if (VT.isVector()) {
    return EVT::getVectorVT(Context, MVT::i1, VT.getVectorNumElements());
  } else {
    return MVT::i32;
  }
}

// This is called to determine if a VECTOR_SHUFFLE should be lowered by this
// file.
bool NyuziTargetLowering::isShuffleMaskLegal(ArrayRef<int> Mask,
                                             EVT VT) const {
  if (Mask.size() != 16)
    return false;

  for (int val : Mask) {
    if (val > 31)
      return false;
  }

  return true;
}

bool NyuziTargetLowering::isIntDivCheap(EVT, AttributeList) const {
  return false;
}

bool NyuziTargetLowering::shouldInsertFencesForAtomic(
    const Instruction *I) const {
  return true;
}

SDValue NyuziTargetLowering::getTargetNode(const GlobalAddressSDNode *N, EVT Ty,
                                           SelectionDAG &DAG,
                                           unsigned int Flag) const {
  return DAG.getTargetGlobalAddress(N->getGlobal(), SDLoc(N), Ty, 0, Flag);
}

SDValue NyuziTargetLowering::getTargetNode(const JumpTableSDNode *N, EVT Ty,
                                           SelectionDAG &DAG,
                                           unsigned int Flag) const {
  return DAG.getTargetJumpTable(N->getIndex(), Ty, Flag);
}

SDValue NyuziTargetLowering::getTargetNode(const ConstantPoolSDNode *N, EVT Ty,
                                           SelectionDAG &DAG,
                                           unsigned int Flag) const {
  return DAG.getTargetConstantPool(N->getConstVal(), Ty, N->getAlignment(),
                                   N->getOffset(), Flag);
}

SDValue NyuziTargetLowering::getTargetNode(const BlockAddressSDNode *N, EVT Ty,
                                           SelectionDAG &DAG,
                                           unsigned int Flag) const {
  return DAG.getTargetBlockAddress(N->getBlockAddress(), Ty, 0, Flag);
}

template <class NodeTy>
SDValue NyuziTargetLowering::getAddr(const NodeTy *N, SelectionDAG &DAG) const {
  SDLoc DL(N);
  EVT Ty = getPointerTy(DAG.getDataLayout());
  if (isPositionIndependent()) {
    // (load (wrapper gp, got(sym))
    SDValue GPReg = DAG.getRegister(Nyuzi::GP_REG, MVT::i32);
    SDValue Wrapper = DAG.getNode(NyuziISD::GOT_ADDR, DL, Ty, GPReg,
                              getTargetNode(N, Ty, DAG, Nyuzi::MO_GOT));
    return DAG.getLoad(Ty, DL, DAG.getEntryNode(), Wrapper,
      MachinePointerInfo::getGOT(DAG.getMachineFunction()));
  } else {
    SDValue Hi = getTargetNode(N, Ty, DAG, Nyuzi::MO_ABS_HI);
    SDValue Lo = getTargetNode(N, Ty, DAG, Nyuzi::MO_ABS_LO);
    SDValue MoveHi = DAG.getNode(NyuziISD::MOVEHI, DL, MVT::i32, Hi);
    return DAG.getNode(NyuziISD::ORLO, DL, MVT::i32, MoveHi, Lo);
  }
}

SDValue NyuziTargetLowering::LowerGlobalAddress(SDValue Op,
                                                SelectionDAG &DAG) const {
  const GlobalAddressSDNode *N = cast<GlobalAddressSDNode>(Op);
  return getAddr(N, DAG);
}

SDValue NyuziTargetLowering::LowerJumpTable(SDValue Op,
                                            SelectionDAG &DAG) const {
  JumpTableSDNode *N = cast<JumpTableSDNode>(Op);
  return getAddr(N, DAG);
}

SDValue NyuziTargetLowering::LowerConstantPool(SDValue Op,
                                               SelectionDAG &DAG) const {
  ConstantPoolSDNode *N = cast<ConstantPoolSDNode>(Op);
  return getAddr(N, DAG);
}

SDValue NyuziTargetLowering::LowerBlockAddress(SDValue Op,
                                               SelectionDAG &DAG) const {
  const BlockAddressSDNode *N = cast<BlockAddressSDNode>(Op);
  return getAddr(N, DAG);
}

SDValue NyuziTargetLowering::LowerBUILD_VECTOR(SDValue Op,
                                               SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);

  if (VT != MVT::v16i1) {
    if (isSplatVector(Op.getNode())) {
      // This is a constant node that is duplicated to all lanes.
      // Convert it to a SPLAT node.
      return DAG.getNode(NyuziISD::SPLAT, DL, VT, Op.getOperand(0));
    }

    return SDValue(); // Expand
  }

  if (ISD::isBuildVectorOfConstantSDNodes(Op.getNode())) {
    // If i1 vectors reach the constant pool, they get translated into a byte
    // array with one byte per i1. This is wrong for this target as v16i1 are
    // stored as tightly packed bit masks. So we compute the packed bit vector
    // as an int and store *that* in the constant pool.
    uint64_t Bits = 0, LaneIndex = 0;
    for (auto Operand : Op.getNode()->op_values()) {
      if (auto C = dyn_cast<ConstantSDNode>(Operand)) {
        Bits |= (C->getZExtValue() & 1) << LaneIndex;
      } else {
        // Lane is undef, treat as 0. This might allow the
        // resulting value to fit into in an immediate operand.
        assert(Operand.getOpcode() == ISD::UNDEF);
      }
      ++LaneIndex;
    }
    // Only 16 bits are needed, but i16 is not legal, so just use 32 bit.
    auto BitsConstant = DAG.getConstant(Bits, DL, MVT::i32);
    return DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, BitsConstant);
  } else {
    // Non-constant BUILD_VECTOR. Expanding is incorrect for the same reason
    // as in the constant case, so do insertions manually.
    SDValue Bitmask = DAG.getConstant(0, DL, MVT::i32);
    for (int i = 15; i >= 0; --i) {
      // The elements may be arbitrary i32 values, truncate them
      // (in accordance with the definition of BUILD_VECTOR).
      auto LaneBit = DAG.getNode(ISD::AND, DL, MVT::i32, Op.getOperand(i),
                                 DAG.getConstant(1, DL, MVT::i32));
      Bitmask = DAG.getNode(ISD::SHL, DL, MVT::i32, Bitmask,
                            DAG.getConstant(1, DL, MVT::i32));
      Bitmask = DAG.getNode(ISD::OR, DL, MVT::i32, Bitmask, LaneBit);
    }
    return DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, Bitmask);
  }
}

// VECTOR_SHUFFLE(vec1, vec2, shuffle_indices)
SDValue NyuziTargetLowering::LowerVECTOR_SHUFFLE(SDValue Op,
                                                 SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  ShuffleVectorSDNode *ShuffleNode = cast<ShuffleVectorSDNode>(Op);
  SDLoc DL(Op);

  if (VT == MVT::v16i1) {
    // There is no instruction for shuffling bits, so extend to i32,
    // shuffle those, and truncate back.
    SDValue ExtVec0 =
        DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::v16i32, Op.getOperand(0));
    SDValue ExtVec1 =
        DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::v16i32, Op.getOperand(1));
    SDValue ExtShuffle = DAG.getVectorShuffle(MVT::v16i32, DL, ExtVec0, ExtVec1,
                                              ShuffleNode->getMask());
    return DAG.getNode(ISD::TRUNCATE, DL, MVT::v16i1, ExtShuffle);
  }

  // Analyze the vector indices.
  unsigned int Mask = 0;
  bool IsIdentityShuffle = true;
  bool IsSplat = true;
  int SplatIndex = 0;
  Constant *ShuffleIndexValues[16];

  for (int SourceLane = 0; SourceLane < 16; SourceLane++) {
    int DestLaneIndex = ShuffleNode->getMaskElt(SourceLane);
    // If this is undef (-1), set to zero. There is potential for optimizations
    // here, although this is rare.
    if (DestLaneIndex < 0)
      DestLaneIndex = 0;

    Mask >>= 1;
    if (DestLaneIndex > 15)
      Mask |= 0x8000;

    if ((DestLaneIndex & 15) != SourceLane)
      IsIdentityShuffle = false;

    if (SourceLane == 0)
      SplatIndex = DestLaneIndex;
    else if (SplatIndex != DestLaneIndex)
      IsSplat = false;

    ShuffleIndexValues[SourceLane] = ConstantInt::get(
        Type::getInt32Ty(*DAG.getContext()), DestLaneIndex & 15);
  }

  // Check if the operands are equal
  if (Op.getOperand(0) == Op.getOperand(1))
    Mask = 0;

  // XXX could check if either operand is undef and change the mask
  // accordingly...

  // scalar_to_vector loads a scalar element into the lowest lane of the vector.
  // The higher lanes are undefined (which means we can load the same value into
  // them using splat).
  // %single = scalar_to_vector i32 %b
  if (Op.getOperand(0).getOpcode() == ISD::SCALAR_TO_VECTOR && Mask == 0)
    return DAG.getNode(NyuziISD::SPLAT, DL, VT, Op.getOperand(0).getOperand(0));

  if (IsSplat) {
    // Check if this builds a splat using shufflevector like this:
    // %single = insertelement <16 x i32> (don't care), i32 %value, i32 <index>
    // %vector = shufflevector <16 x i32> %single, <16 x i32> (don't care),
    //                         <16 x i32> <...index...>
    if (Op.getOperand(0).getOpcode() == ISD::INSERT_VECTOR_ELT &&
        SplatIndex ==
            cast<ConstantSDNode>(Op.getOperand(0).getOperand(2))
                ->getSExtValue()) {
      return DAG.getNode(NyuziISD::SPLAT, DL, VT,
                         Op.getOperand(0).getOperand(1));
    }

    // This is a splat where the element is taken from another vector that
    // we don't know the value of. First extract element, then broadcast it.
    SDValue SourceVector =
        SplatIndex < 16 ? Op.getOperand(0) : Op.getOperand(1);
    SDValue LaneIndexValue = DAG.getConstant(SplatIndex % 16, DL, MVT::i32);
    SDValue LaneValue = DAG.getNode(ISD::EXTRACT_VECTOR_ELT, DL, MVT::i32,
                                    SourceVector, LaneIndexValue);
    return DAG.getNode(NyuziISD::SPLAT, DL, VT, LaneValue);
  }

  Constant *ShuffleConstVector = ConstantVector::get(ShuffleIndexValues);
  SDValue ShuffleVectorCP =
      DAG.getConstantPool(ShuffleConstVector, MVT::v16i32);
  SDValue ShuffleVector = DAG.getLoad(
      MVT::v16i32, DL, DAG.getEntryNode(), ShuffleVectorCP,
      MachinePointerInfo::getConstantPool(DAG.getMachineFunction()), 64);

  SDValue NativeShuffleIntr = DAG.getConstant(VT.isFloatingPoint()
    ? Intrinsic::nyuzi_shufflef : Intrinsic::nyuzi_shufflei, DL, MVT::i32);
  if (Mask == 0xffff || Mask == 0) {
    // Only one of the vectors is referenced.
    SDValue ShuffleSource = Mask == 0 ? Op.getOperand(0) : Op.getOperand(1);

    if (IsIdentityShuffle)
      return ShuffleSource; // Is just a copy
    else
      return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, VT,
                         NativeShuffleIntr, ShuffleSource, ShuffleVector);
  } else if (IsIdentityShuffle) {
    // This is just a mix
    SDValue MaskInt = DAG.getConstant(Mask, DL, MVT::i32);
    SDValue MaskVal = DAG.getNode(NyuziISD::MASK_FROM_INT,
                                  DL, MVT::v16i1, MaskInt);
    return DAG.getNode(ISD::VSELECT, DL, VT,
                       MaskVal, Op.getOperand(1), Op.getOperand(0));
  } else {
    // Need to shuffle both vectors and mix
    SDValue Shuffled0 =
        DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, MVT::v16i32, NativeShuffleIntr,
                    Op.getOperand(0), ShuffleVector);
    SDValue Shuffled1 =
        DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, MVT::v16i32, NativeShuffleIntr,
                    Op.getOperand(1), ShuffleVector);

    SDValue MaskInt = DAG.getConstant(Mask, DL, MVT::i32);
    SDValue MaskVal = DAG.getNode(NyuziISD::MASK_FROM_INT,
                                  DL, MVT::v16i1, MaskInt);
    return DAG.getNode(ISD::VSELECT, DL, VT,
                       MaskVal, Shuffled1, Shuffled0);
  }
}

// (VECTOR, VAL, IDX)
SDValue NyuziTargetLowering::LowerINSERT_VECTOR_ELT(SDValue Op,
                                                    SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue LaneIndex = Op.getOperand(2);
  SDValue LaneMask = DAG.getNode(ISD::SHL, DL, MVT::i32,
                                 DAG.getConstant(1, DL, MVT::i32), LaneIndex);
  MVT VT = Op.getValueType().getSimpleVT();
  if (VT == MVT::v16i1) {
    // The element is promoted to i32 and the vector is in a scalar
    // register, so we can't do a vselect as for other element types.
    // Instead, insert by bit manipulation:
    // (VECTOR & !LaneMask) | (VAL << IDX)
    SDValue ElemBit = DAG.getNode(ISD::AND, DL, MVT::i32, Op.getOperand(1),
                                  DAG.getConstant(1, DL, MVT::i32));
    SDValue SetBit = DAG.getNode(ISD::SHL, DL, MVT::i32, ElemBit, LaneIndex);
    SDValue UnsetBit = DAG.getNOT(DL, LaneMask, MVT::i32);
    SDValue VecAsInt =
        DAG.getNode(NyuziISD::MASK_TO_INT, DL, MVT::i32, Op.getOperand(0));
    SDValue Result =
        DAG.getNode(ISD::OR, DL, MVT::i32, SetBit,
                    DAG.getNode(ISD::AND, DL, MVT::i32, VecAsInt, UnsetBit));
    return DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, Result);
  } else {
    // Put the element into the right lane with a masked move.
    SDValue Splat = DAG.getNode(NyuziISD::SPLAT, DL, VT, Op.getOperand(1));
    SDValue MaskVec =
        DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, LaneMask);
    return DAG.getNode(ISD::VSELECT, DL, VT, MaskVec, Splat,
                       Op.getOperand(0));
  }
}

SDValue NyuziTargetLowering::LowerEXTRACT_VECTOR_ELT(SDValue Op,
                                                     SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue Vector = Op.getOperand(0);
  SDValue LaneIndex = Op.getOperand(1);

  if (Vector.getSimpleValueType() != MVT::v16i1) {
    // Let isel make it a getlane
    return Op;
  }

  // Extract the bit by shifting.
  SDValue MaskBits = DAG.getNode(NyuziISD::MASK_TO_INT, DL, MVT::i32, Vector);
  SDValue Elem = DAG.getNode(ISD::SRL, DL, MVT::i32, MaskBits, LaneIndex);
  // FIXME: could we skip masking out the higher bits?
  return DAG.getNode(ISD::AND, DL, MVT::i32, Elem,
                     DAG.getConstant(1, DL, MVT::i32));
}

SDValue NyuziTargetLowering::LowerSCALAR_TO_VECTOR(SDValue Op,
                                                   SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);

  // SCALAR_TO_VECTOR loads the scalar register into lane 0 of the register.
  // The rest of the lanes are undefined.
  if (VT == MVT::v16i1) {
    // Lane 0 is the LSB of the mask register, which is exactly matches
    // the operand (i1 promoted to i32), and the other bits don't matter
    // because the corresponding lanes are undef.
    return DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::i32, Op.getOperand(0));
  } else {
    // For simplicity, we just load the same value into all lanes.
    return DAG.getNode(NyuziISD::SPLAT, DL, VT, Op.getOperand(0));
  }
}

// This architecture does not support conditional moves for scalar registers.
// We must convert this into a set of conditional branches. We do this by
// creating a pseudo-instruction SEL_COND_RESULT, which will later be
// transformed.
SDValue NyuziTargetLowering::LowerSELECT_CC(SDValue Op,
                                            SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT Ty = Op.getOperand(0).getValueType();
  SDValue Pred =
      DAG.getNode(ISD::SETCC, DL, getSetCCResultType(DAG.getDataLayout(),
                                                     *DAG.getContext(), Ty),
                  Op.getOperand(0), Op.getOperand(1), Op.getOperand(4));

  return DAG.getNode(NyuziISD::SEL_COND_RESULT, DL, Op.getValueType(), Pred,
                     Op.getOperand(2), Op.getOperand(3));
}

// The default expansion of SELECT with v16i1 operands produces horrible
// code (41 instructions). Convert to a simpler branch.
SDValue NyuziTargetLowering::LowerSELECT(SDValue Op,
                                         SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Pred = DAG.getSetCC(DL, getSetCCResultType(DAG.getDataLayout(),
                              *DAG.getContext(), MVT::i1), Op.getOperand(0),
                              DAG.getConstant(0, DL, MVT::i32), ISD::SETNE);

  return DAG.getNode(NyuziISD::SEL_COND_RESULT, DL, Op.getValueType(), Pred,
                     Op.getOperand(1), Op.getOperand(2));
}

SDValue NyuziTargetLowering::LowerVSELECT(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Mask = Op.getOperand(0);
  SDValue Op1 = Op.getOperand(1);
  SDValue Op2 = Op.getOperand(2);
  if (Op1.getValueType().getSimpleVT() == MVT::v16i1 && Op2.getValueType().getSimpleVT() == MVT::v16i1) {
    SDValue MaskInt = DAG.getNode(NyuziISD::MASK_TO_INT, DL, MVT::i32, Mask);
    SDValue Op1Int = DAG.getNode(NyuziISD::MASK_TO_INT, DL, MVT::i32, Op1);
    SDValue Op2Int = DAG.getNode(NyuziISD::MASK_TO_INT, DL, MVT::i32, Op2);
    SDValue InvertVal = DAG.getConstant(0xffff, DL, MVT::i32);
    SDValue InvertedMask = DAG.getNode(ISD::XOR, DL, MVT::i32, MaskInt, InvertVal);
    SDValue Op1Masked = DAG.getNode(ISD::AND, DL, MVT::i32, Op1Int, MaskInt);
    SDValue Op2Masked = DAG.getNode(ISD::AND, DL, MVT::i32, Op2Int, InvertedMask);
    SDValue Result = DAG.getNode(ISD::OR, DL, MVT::i32, Op1Masked, Op2Masked);
    return DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, Result);
  } else {
    return Op;
  }
}

SDValue NyuziTargetLowering::LowerSETCC(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(2))->get();
  MVT OperandVT = Op.getOperand(0).getSimpleValueType();
  MVT ResultVT = Op.getSimpleValueType();

  // v16i1 comparisons are a bit odd and not generated by normal C code,
  // so we don't really care how efficient it is. Just delegate to
  // full v16i32 comparisons by sext.
  // (If we did care, we could cook up some bitwise operations.)
  // Note: It has to be sext, not zext, as i1 true is the "all ones" value
  // and hence "negative" for the purpose of signed icmp.
  if (OperandVT == MVT::v16i1) {
    SDValue SExtOp0 = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::v16i32,
                                  Op.getOperand(0));
    SDValue SExtOp1 = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::v16i32,
                                  Op.getOperand(1));
    return DAG.getSetCC(DL, MVT::v16i1, SExtOp0, SExtOp1, CC);
  }
  if (OperandVT == MVT::v16i32) {
    // All integer comparisons are legal, nothing to do.
    // XXX why does this even get called? Maybe because v16i1 SETCC is Custom?
    return Op;
  }

  // The main job of this functions is to convert unordered or don't-care
  // floating point comparisions to ordered ones. But we also map legal
  // comparisons to target-specific SDNodes, to ensure the DAG combiner does
  // not undo the work we do here. This does mean losing out on some
  // optimizations, but this is okay as we're consciously choosing a less
  // optimal/canonical form to legalize these comparisons. Besides,
  // this runs very late in the pipeline, usually a constant or redundant
  // comparison would be folded away long before legalization.
  // Some things to keep in mind:
  // - Two comparison values are ordered if neither operand is NaN, otherwise
  //   they are unordered.
  // - An ordered comparison *operation* is always false if either operand is
  //   NaN. Unordered is always true if either operand is NaN.
  // - The hardware implements ordered comparisons.
  // - Clang usually emits ordered comparisons.
  NyuziISD::NodeType ComplementCompare;
  switch (CC) {
  default:
    llvm_unreachable("unhandled float comparison");

  // Ordered comparisons are natively supported, and "don't care"
  // comparisons can be converted to those as well.
  case ISD::SETGT:
  case ISD::SETOGT:
    return morphSETCCNode(Op, NyuziISD::FGT, DAG);
  case ISD::SETGE:
  case ISD::SETOGE:
    return morphSETCCNode(Op, NyuziISD::FGE, DAG);
  case ISD::SETLT:
  case ISD::SETOLT:
    return morphSETCCNode(Op, NyuziISD::FLT, DAG);
  case ISD::SETLE:
  case ISD::SETOLE:
    return morphSETCCNode(Op, NyuziISD::FLE, DAG);
  case ISD::SETEQ:
  case ISD::SETOEQ:
    return morphSETCCNode(Op, NyuziISD::FEQ, DAG);
  case ISD::SETNE:
  case ISD::SETONE:
    return morphSETCCNode(Op, NyuziISD::FNE, DAG);

  // Check for ordered and unordered values by using ordered equality
  // (which will only be false if the values are unordered)
  case ISD::SETO:
  case ISD::SETUO: {
    SDValue Op0 = Op.getOperand(0);
    SDValue IsOrdered =
        DAG.getNode(NyuziISD::FEQ, DL, ResultVT, Op0, Op0);
    if (CC == ISD::SETO)
      return IsOrdered;

    // The hardware sets all 16 bits even for scalar comparisons, so negate
    // them all.
    SDValue Negate = DAG.getConstant(0xffff, DL, MVT::i32);
    if (ResultVT.isVector()) {
      Negate = DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, Negate);
    }
    return DAG.getNode(ISD::XOR, DL, ResultVT, IsOrdered, Negate);
  }

  // Convert unordered comparisions to ordered by explicitly checking for NaN
  case ISD::SETUEQ:
    ComplementCompare = NyuziISD::FNE;
    break;
  case ISD::SETUGT:
    ComplementCompare = NyuziISD::FLE;
    break;
  case ISD::SETUGE:
    ComplementCompare = NyuziISD::FLT;
    break;
  case ISD::SETULT:
    ComplementCompare = NyuziISD::FGE;
    break;
  case ISD::SETULE:
    ComplementCompare = NyuziISD::FGT;
    break;
  case ISD::SETUNE:
    ComplementCompare = NyuziISD::FEQ;
    break;
  }

  // Take the complementary comparision and invert the result. This will
  // be the same for ordered values, but will always be true for unordered
  // values.
  SDValue Comp2 = morphSETCCNode(Op, ComplementCompare, DAG);
  // The hardware sets all 16 bits even for scalar comparisons, so negate
  // them all.
  SDValue Negate = DAG.getConstant(0xffff, DL, MVT::i32);
  if (ResultVT.isVector()) {
    Negate = DAG.getNode(NyuziISD::MASK_FROM_INT, DL, MVT::v16i1, Negate);
  }
  return DAG.getNode(ISD::XOR, DL, ResultVT, Comp2, Negate);
}

// There is no native floating point division, but we can convert this to a
// reciprocal/multiply operation.  If the first parameter is constant 1.0, then
// just a reciprocal will suffice.
SDValue NyuziTargetLowering::LowerFDIV(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);

  EVT Type = Op.getOperand(1).getValueType();

  SDValue Two = DAG.getConstantFP(2.0, DL, Type);
  SDValue Denominator = Op.getOperand(1);
  SDValue Estimate =
      DAG.getNode(NyuziISD::RECIPROCAL_EST, DL, Type, Denominator);

  // Perform a series of Newton Raphson refinements to determine 1/divisor. Each
  // iteration doubles the precision of the result. The initial estimate has 6
  // bits of precision, so two iterations results in 24 bits, which is larger
  // than the (23 bit) significand.

  for (int i = 0; i < 2; i++) {
    // Trial = x * Estimate (our target is for x * 1/x to be 1.0)
    // Error = 2.0 - Trial
    // Estimate = Estimate * Error
    SDValue Trial = DAG.getNode(ISD::FMUL, DL, Type, Estimate, Denominator);
    SDValue Error = DAG.getNode(ISD::FSUB, DL, Type, Two, Trial);
    Estimate = DAG.getNode(ISD::FMUL, DL, Type, Estimate, Error);
  }

  // Check if the first parameter is constant 1.0.  If so, we don't need
  // to multiply by the dividend.
  bool IsOne = false;
  if (Type.isVector()) {
    if (isSplatVector(Op.getOperand(0).getNode())) {
      ConstantFPSDNode *C =
          dyn_cast<ConstantFPSDNode>(Op.getOperand(0).getOperand(0));
      IsOne = C && C->isExactlyValue(1.0);
    }
  } else {
    ConstantFPSDNode *C = dyn_cast<ConstantFPSDNode>(Op.getOperand(0));
    IsOne = C && C->isExactlyValue(1.0);
  }

  if (!IsOne)
    Estimate = DAG.getNode(ISD::FMUL, DL, Type, Op.getOperand(0), Estimate);

  return Estimate;
}

// There is no native FNEG instruction, so we emulate it by XORing with
// 0x80000000
SDValue NyuziTargetLowering::LowerFNEG(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  MVT ResultVT = Op.getValueType().getSimpleVT();
  MVT IntermediateVT = ResultVT.isVector() ? MVT::v16i32 : MVT::i32;

  SDValue rhs = DAG.getConstant(0x80000000, DL, MVT::i32);
  SDValue iconv;
  if (ResultVT.isVector())
    rhs = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32, rhs);

  iconv = DAG.getBitcast(IntermediateVT, Op.getOperand(0));
  SDValue flipped = DAG.getNode(ISD::XOR, DL, IntermediateVT, iconv, rhs);
  return DAG.getBitcast(ResultVT, flipped);
}

// Mask off the sign bit
SDValue NyuziTargetLowering::LowerFABS(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  MVT ResultVT = Op.getValueType().getSimpleVT();
  MVT IntermediateVT = ResultVT.isVector() ? MVT::v16i32 : MVT::i32;

  SDValue rhs = DAG.getConstant(0x7fffffff, DL, MVT::i32);
  SDValue iconv;
  if (ResultVT.isVector())
    rhs = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32, rhs);

  iconv = DAG.getBitcast(IntermediateVT, Op.getOperand(0));
  SDValue flipped = DAG.getNode(ISD::AND, DL, IntermediateVT, iconv, rhs);
  return DAG.getBitcast(ResultVT, flipped);
}

SDValue NyuziTargetLowering::LowerVASTART(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  MachineFunction &MF = DAG.getMachineFunction();
  NyuziMachineFunctionInfo *VFI = MF.getInfo<NyuziMachineFunctionInfo>();
  SDValue FI = DAG.getFrameIndex(VFI->getVarArgsFrameIndex(),
                                 getPointerTy(DAG.getDataLayout()));
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), DL, FI, Op.getOperand(1),
                      MachinePointerInfo(SV));
}

SDValue NyuziTargetLowering::LowerCTLZ_ZERO_UNDEF(SDValue Op,
                                                  SelectionDAG &DAG) const {
  SDLoc DL(Op);
  return DAG.getNode(ISD::CTLZ, DL, Op.getValueType(), Op.getOperand(0));
}

SDValue NyuziTargetLowering::LowerCTTZ_ZERO_UNDEF(SDValue Op,
                                                  SelectionDAG &DAG) const {
  SDLoc DL(Op);
  return DAG.getNode(ISD::CTTZ, DL, Op.getValueType(), Op.getOperand(0));
}

SDValue NyuziTargetLowering::LowerUINT_TO_FP(SDValue Op,
                                             SelectionDAG &DAG) const {
  SDLoc DL(Op);

  assert(Op.getOperand(0).getSimpleValueType() == MVT::v16i1);

  // Convert a v16i1 mask into floating point values with predicated
  // move.
  EVT ElementType = Op.getValueType().getVectorElementType();
  SDValue FalseVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16f32,
                                 DAG.getConstantFP(0.0, DL, ElementType));
  SDValue TrueVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16f32,
                                DAG.getConstantFP(1.0, DL, ElementType));
  return DAG.getNode(ISD::VSELECT, DL, MVT::v16f32, Op.getOperand(0),
                     TrueVal, FalseVal);
}

SDValue NyuziTargetLowering::LowerSINT_TO_FP(SDValue Op,
                                             SelectionDAG &DAG) const {
  SDLoc DL(Op);

  // Convert a v16i1 mask into floating point values with predicated
  // move. This is similar to UINT_TO_FP, but the values are sign
  // extended so they are negative.
  EVT ElementType = Op.getValueType().getVectorElementType();
  SDValue FalseVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16f32,
                                 DAG.getConstantFP(0.0, DL, ElementType));
  SDValue TrueVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16f32,
                                DAG.getConstantFP(-1.0, DL, ElementType));
  return DAG.getNode(ISD::VSELECT, DL, MVT::v16f32, Op.getOperand(0),
                     TrueVal, FalseVal);
}

SDValue NyuziTargetLowering::LowerFRAMEADDR(SDValue Op,
                                            SelectionDAG &DAG) const {
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Frame address can only be determined for current frame.");

  SDLoc DL(Op);
  MachineFrameInfo &MFI = DAG.getMachineFunction().getFrameInfo();
  MFI.setFrameAddressIsTaken(true);
  EVT VT = Op.getValueType();
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, Nyuzi::FP_REG, VT);
}

SDValue NyuziTargetLowering::LowerRETURNADDR(SDValue Op,
                                             SelectionDAG &DAG) const {
  if (verifyReturnAddressArgumentIsConstant(Op, DAG))
    return SDValue();

  // check the depth
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Return address can be determined only for current frame.");

  SDLoc DL(Op);
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MVT VT = Op.getSimpleValueType();
  MFI.setReturnAddressIsTaken(true);

  // Return RA, which contains the return address. Mark it an implicit live-in.
  unsigned Reg = MF.addLiveIn(Nyuzi::RA_REG, getRegClassFor(VT));
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, Reg, VT);
}

// Sign extension from v16i1 to v16i32, commonly emitted by clang
// for vector comparisons. As v16i1 is a compact bitmask, this is
// not a lane-wise sext, it needs a select predicated on the mask.
// Note that sign extension of i1 true is i32 -1, not i32 1.
SDValue NyuziTargetLowering::LowerSIGN_EXTEND(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue FalseVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32,
                                 DAG.getConstant(0, DL, MVT::i32));
  SDValue TrueVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32,
                                DAG.getConstant(0xffffffff, DL, MVT::i32));
  SDValue Mask = Op.getOperand(0);
  return DAG.getNode(ISD::VSELECT, DL, MVT::v16i32, Mask, TrueVal, FalseVal);
}

// Zero extension from v16i1 to v16i32, used for example when lowering
// v16i1 shuffles. As v16i1 is a compact bitmask, this is not a lane-wise
// zext, it needs a select predicated on the mask.
SDValue NyuziTargetLowering::LowerZERO_EXTEND(SDValue Op,
                                              SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue FalseVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32,
                                 DAG.getConstant(0, DL, MVT::i32));
  SDValue TrueVal = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32,
                                DAG.getConstant(1, DL, MVT::i32));
  SDValue Mask = Op.getOperand(0);
  return DAG.getNode(ISD::VSELECT, DL, MVT::v16i32, Mask, TrueVal, FalseVal);
}

// Truncation from v16i32 to v16i1, used for example when lowering
// v16i1 shuffles. Masks out the high bits of each i32 lane,
// then compares the low bit of each lane to 1 to build a v16i1
// that is true in the lanes where the v16i32 had its LSB set.
SDValue NyuziTargetLowering::LowerTRUNCATE(SDValue Op,
                                           SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue Op0 = Op.getOperand(0);
  SDValue OnesVec = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16i32,
                                DAG.getConstant(1, DL, MVT::i32));
  SDValue LaneBits = DAG.getNode(ISD::AND, DL, MVT::v16i32, Op0, OnesVec);
  return DAG.getSetCC(DL, MVT::v16i1, LaneBits, OnesVec, ISD::SETEQ);
}

// This is only called when converting a floating point number to
// v16i1. This is an odd operation, but added for completeness.
// The result is same for unsigned or signed, so both versions call
// here.
SDValue NyuziTargetLowering::LowerFP_TO_XINT(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  SDValue Zero = DAG.getNode(NyuziISD::SPLAT, DL, MVT::v16f32,
                             DAG.getConstantFP(0.0, DL, MVT::f32));
  return DAG.getSetCC(DL, MVT::v16i1, Op.getOperand(0), Zero, ISD::SETNE);
}

MachineBasicBlock *
NyuziTargetLowering::EmitSelectCC(MachineInstr &MI,
                                  MachineBasicBlock *BB) const {
  const TargetInstrInfo *TII = Subtarget.getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  // The instruction we are replacing is SELECTI (Dest, predicate, trueval,
  // falseval)

  // To "insert" a SELECT_CC instruction, we actually have to rewrite it into a
  // diamond control-flow pattern.  The incoming instruction knows the
  // destination vreg to set, the condition code register to branch on, the
  // true/false values to select between, and a branch opcode to use.
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = BB->getIterator();
  ++It;

  //  ThisMBB:
  //  ...
  //   TrueVal = ...
  //   setcc r1, r2, r3
  //   if r1 goto copy1MBB
  //   fallthrough --> Copy0MBB
  MachineBasicBlock *ThisMBB = BB;
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *Copy0MBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *SinkMBB = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, Copy0MBB);
  F->insert(It, SinkMBB);

  // Transfer the remainder of BB and its successor edges to SinkMBB.
  SinkMBB->splice(SinkMBB->begin(), BB,
                  std::next(MachineBasicBlock::iterator(MI)), BB->end());
  SinkMBB->transferSuccessorsAndUpdatePHIs(BB);

  // Next, add the true and fallthrough blocks as its successors.
  BB->addSuccessor(Copy0MBB);
  BB->addSuccessor(SinkMBB);

  BuildMI(BB, DL, TII->get(Nyuzi::BNZ))
      .addReg(MI.getOperand(1).getReg())
      .addMBB(SinkMBB);

  //  Copy0MBB:
  //   %FalseValue = ...
  //   # fallthrough to SinkMBB
  BB = Copy0MBB;

  // Update machine-CFG edges
  BB->addSuccessor(SinkMBB);

  //  SinkMBB:
  //   %Result = phi [ %TrueValue, ThisMBB ], [ %FalseValue, Copy0MBB ]
  //  ...
  BB = SinkMBB;

  BuildMI(*BB, BB->begin(), DL, TII->get(Nyuzi::PHI), MI.getOperand(0).getReg())
      .addReg(MI.getOperand(2).getReg())
      .addMBB(ThisMBB)
      .addReg(MI.getOperand(3).getReg())
      .addMBB(Copy0MBB);

  MI.eraseFromParent(); // The pseudo instruction is gone now.
  return BB;
}

MachineBasicBlock *
NyuziTargetLowering::EmitAtomicBinary(MachineInstr &MI, MachineBasicBlock *BB,
                                      unsigned Opcode, bool InvertResult) const {
  const TargetInstrInfo *TII = Subtarget.getInstrInfo();

  unsigned Dest = MI.getOperand(0).getReg();
  unsigned Ptr = MI.getOperand(1).getReg();
  DebugLoc DL = MI.getDebugLoc();
  MachineRegisterInfo &MRI = BB->getParent()->getRegInfo();
  unsigned Success = MRI.createVirtualRegister(&Nyuzi::GPR32RegClass);
  unsigned NewValue = MRI.createVirtualRegister(&Nyuzi::GPR32RegClass);

  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction *MF = BB->getParent();
  MachineFunction::iterator It = BB->getIterator();
  ++It;

  MachineBasicBlock *LoopMBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *ExitMBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MF->insert(It, LoopMBB);
  MF->insert(It, ExitMBB);

  // Transfer the remainder of BB and its successor edges to ExitMBB.
  ExitMBB->splice(ExitMBB->begin(), BB,
                  std::next(MachineBasicBlock::iterator(MI)), BB->end());
  ExitMBB->transferSuccessorsAndUpdatePHIs(BB);

  //  ThisMBB:
  BB->addSuccessor(LoopMBB);

  //  LoopMBB:
  BB = LoopMBB;

  if (Opcode != 0) {
    unsigned OldValue = MRI.createVirtualRegister(&Nyuzi::GPR32RegClass);

    BuildMI(BB, DL, TII->get(Nyuzi::LOAD_SYNC), OldValue).addReg(Ptr).addImm(0);
    BuildMI(BB, DL, TII->get(Nyuzi::MOVESS), Dest).addReg(OldValue);
    if (MI.getOperand(2).getType() == MachineOperand::MO_Register) {
      BuildMI(BB, DL, TII->get(Opcode), NewValue)
          .addReg(OldValue)
          .addReg(MI.getOperand(2).getReg());
    } else if (MI.getOperand(2).getType() == MachineOperand::MO_Immediate) {
      BuildMI(BB, DL, TII->get(Opcode), NewValue)
          .addReg(OldValue)
          .addImm(MI.getOperand(2).getImm());
    } else
      llvm_unreachable("Unknown operand type");

    if (InvertResult) {
      // This is used with AND to create NAND.
      unsigned int Inverted = MRI.createVirtualRegister(&Nyuzi::GPR32RegClass);
      BuildMI(BB, DL, TII->get(Nyuzi::XORSSI), Inverted)
          .addReg(NewValue)
          .addImm(-1);
      NewValue = Inverted;
    }
  } else {
    // Atomic swap
    BuildMI(BB, DL, TII->get(Nyuzi::LOAD_SYNC), Dest).addReg(Ptr).addImm(0);
    BuildMI(BB, DL, TII->get(Nyuzi::MOVESS), NewValue).addReg(
            MI.getOperand(2).getReg());
  }

  BuildMI(BB, DL, TII->get(Nyuzi::STORE_SYNC), Success)
      .addReg(NewValue)
      .addReg(Ptr)
      .addImm(0);
  BuildMI(BB, DL, TII->get(Nyuzi::BZ)).addReg(Success).addMBB(LoopMBB);
  BB->addSuccessor(LoopMBB);
  BB->addSuccessor(ExitMBB);

  //  ExitMBB:
  BB = ExitMBB;

  MI.eraseFromParent(); // The instruction is gone now.

  return BB;
}

MachineBasicBlock *
NyuziTargetLowering::EmitAtomicCmpSwap(MachineInstr &MI,
                                       MachineBasicBlock *BB) const {
  MachineFunction *MF = BB->getParent();
  MachineRegisterInfo &RegInfo = MF->getRegInfo();
  const TargetRegisterClass *RC = getRegClassFor(MVT::i32);
  const TargetInstrInfo *TII = Subtarget.getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();

  unsigned Dest = MI.getOperand(0).getReg();
  unsigned Ptr = MI.getOperand(1).getReg();
  unsigned OldVal = MI.getOperand(2).getReg();
  unsigned NewVal = MI.getOperand(3).getReg();

  unsigned Success = RegInfo.createVirtualRegister(RC);
  unsigned CmpResult = RegInfo.createVirtualRegister(RC);

  // insert new blocks after the current block
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineBasicBlock *Loop1MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *Loop2MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *ExitMBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineFunction::iterator It = BB->getIterator();
  ++It;
  MF->insert(It, Loop1MBB);
  MF->insert(It, Loop2MBB);
  MF->insert(It, ExitMBB);

  // Transfer the remainder of BB and its successor edges to ExitMBB.
  ExitMBB->splice(ExitMBB->begin(), BB,
                  std::next(MachineBasicBlock::iterator(MI)), BB->end());
  ExitMBB->transferSuccessorsAndUpdatePHIs(BB);

  //  ThisMBB:
  //    ...
  //    fallthrough --> Loop1MBB
  BB->addSuccessor(Loop1MBB);
  Loop1MBB->addSuccessor(ExitMBB);
  Loop1MBB->addSuccessor(Loop2MBB);
  Loop2MBB->addSuccessor(Loop1MBB);
  Loop2MBB->addSuccessor(ExitMBB);

  // Loop1MBB:
  //   load.sync Dest, 0(Ptr)
  //   setne cmpresult, Dest, oldval
  //   btrue cmpresult, ExitMBB
  BB = Loop1MBB;
  BuildMI(BB, DL, TII->get(Nyuzi::LOAD_SYNC), Dest).addReg(Ptr).addImm(0);
  BuildMI(BB, DL, TII->get(Nyuzi::SNESISS), CmpResult)
      .addReg(Dest)
      .addReg(OldVal);
  BuildMI(BB, DL, TII->get(Nyuzi::BNZ)).addReg(CmpResult).addMBB(ExitMBB);

  // Loop2MBB:
  //   move success, newval			; need a temporary because
  //   store.sync success, 0(Ptr)	; store.sync will clobber success
  //   bfalse success, Loop1MBB
  BB = Loop2MBB;
  BuildMI(BB, DL, TII->get(Nyuzi::STORE_SYNC), Success)
      .addReg(NewVal)
      .addReg(Ptr)
      .addImm(0);
  BuildMI(BB, DL, TII->get(Nyuzi::BZ)).addReg(Success).addMBB(Loop1MBB);

  MI.eraseFromParent(); // The instruction is gone now.

  return ExitMBB;
}
