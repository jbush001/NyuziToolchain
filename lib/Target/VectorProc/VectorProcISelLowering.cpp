//===-- VectorProcISelLowering.cpp - VectorProc DAG Lowering Implementation
//---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the interfaces that VectorProc uses to lower LLVM code
// into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "isel"
#include "VectorProcISelLowering.h"
#include "VectorProcMachineFunctionInfo.h"
#include "VectorProcTargetMachine.h"
#include "VectorProcTargetObjectFile.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
#include "llvm/IR/Intrinsics.h"
using namespace llvm;

#include "VectorProcGenCallingConv.inc"

SDValue VectorProcTargetLowering::LowerReturn(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs,
    const SmallVectorImpl<SDValue> &OutVals, SDLoc DL,
    SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();

  // CCValAssign - represent the assignment of the return value to locations.
  SmallVector<CCValAssign, 16> RVLocs;

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(), DAG.getTarget(),
                 RVLocs, *DAG.getContext());

  // Analyze return values.
  CCInfo.AnalyzeReturn(Outs, RetCC_VectorProc32);

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

  if (MF.getFunction()->hasStructRetAttr()) {
    VectorProcMachineFunctionInfo *VFI = MF.getInfo<VectorProcMachineFunctionInfo>();
    unsigned Reg = VFI->getSRetReturnReg();
    if (!Reg)
      llvm_unreachable("sret virtual register not created in the entry block");

    SDValue Val = DAG.getCopyFromReg(Chain, DL, Reg, getPointerTy());
    Chain = DAG.getCopyToReg(Chain, DL, VectorProc::S0, Val, Flag);
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VectorProc::S0, getPointerTy()));
  }

  RetOps[0] = Chain; // Update chain.

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(VectorProcISD::RET_FLAG, DL, MVT::Other, RetOps);
}

SDValue VectorProcTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, SDLoc DL, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  // Analyze operands of the call, assigning locations to each operand.
  // VectorProcCallingConv.td will auto-generate CC_VectorProc32, which
  // knows how to handle operands (what go in registers vs. stack, etc).
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_VectorProc32);

  // Walk through each parameter and push into InVals
  int ParamEndOffset = 0;
  for (const auto &VA : ArgLocs) {
    if (VA.isRegLoc()) {
      // Argument is in register
      EVT RegVT = VA.getLocVT();
      const TargetRegisterClass *RC;

      if (RegVT == MVT::i32 || RegVT == MVT::f32)
        RC = &VectorProc::GPR32RegClass;
      else if (RegVT == MVT::v16i32 || RegVT == MVT::v16f32)
        RC = &VectorProc::VR512RegClass;
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
    int FI = MF.getFrameInfo()->CreateFixedObject(ParamSize, ParamOffset, true);
    ParamEndOffset = ParamOffset + ParamSize;

    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy());
    SDValue Load;
    if (VA.getValVT() == MVT::i32 || VA.getValVT() == MVT::f32 ||
        VA.getValVT() == MVT::v16i32) {
      // Primitive Types are loaded directly from the stack
      Load = DAG.getLoad(VA.getValVT(), DL, Chain, FIPtr, MachinePointerInfo(),
                         false, false, false, 0);
    } else {
      // This is a smaller Type (char, etc).  Sign extend.
      ISD::LoadExtType LoadOp = ISD::SEXTLOAD;
      unsigned Offset = 4 - std::max(1U, VA.getValVT().getSizeInBits() / 8);
      FIPtr = DAG.getNode(ISD::ADD, DL, MVT::i32, FIPtr,
                          DAG.getConstant(Offset, MVT::i32));
      Load = DAG.getExtLoad(LoadOp, DL, MVT::i32, Chain, FIPtr,
                            MachinePointerInfo(), VA.getValVT(), false, false, 0);
      Load = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), Load);
    }

    InVals.push_back(Load);
  }

  VectorProcMachineFunctionInfo *VFI = MF.getInfo<VectorProcMachineFunctionInfo>();

  if (isVarArg) {
    // Create a dummy object where the first parameter would start.  This will be used
    // later to determine the start address of variable arguments.
    int FirstVarArg = MF.getFrameInfo()->CreateFixedObject(4, ParamEndOffset, false);
    VFI->setVarArgsFrameIndex(FirstVarArg);
  }
  
  if (MF.getFunction()->hasStructRetAttr()) {
    // When a function returns a structure, the address of the return value
    // is placed in the first physical register.
    unsigned Reg = VFI->getSRetReturnReg();
    if (!Reg) {
      Reg =
          MF.getRegInfo().createVirtualRegister(&VectorProc::GPR32RegClass);
      VFI->setSRetReturnReg(Reg);
    }

    SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), DL, Reg, InVals[0]);
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, Copy, Chain);
  }

  return Chain;
}

// Generate code to call a function
SDValue
VectorProcTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
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
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const TargetFrameLowering *TFL = MF.getTarget().getFrameLowering();

  // Analyze operands of the call, assigning locations to each operand.
  // VectorProcCallingConv.td will auto-generate CC_VectorProc32, which
  // knows how to handle operands (what go in registers vs. stack, etc).
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), DAG.getTarget(),
                 ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_VectorProc32);

  // Get the size of the outgoing arguments stack space requirement.
  // We always keep the stack pointer 64 byte aligned so we can use block
  // loads/stores for vector arguments
  unsigned ArgsSize = RoundUpToAlignment(CCInfo.getNextStackOffset(), 
    TFL->getStackAlignment());

  // Create local copies for all arguments that are passed by value
  SmallVector<SDValue, 8> ByValArgs;
  for (unsigned i = 0, e = Outs.size(); i != e; ++i) {
    ISD::ArgFlagsTy Flags = Outs[i].Flags;
    if (!Flags.isByVal())
      continue;

    SDValue Arg = OutVals[i];
    unsigned Size = Flags.getByValSize();
    unsigned Align = Flags.getByValAlign();

    int FI = MFI->CreateStackObject(Size, Align, false);
    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy());
    SDValue SizeNode = DAG.getConstant(Size, MVT::i32);
    Chain = DAG.getMemcpy(Chain, DL, FIPtr, Arg, SizeNode, Align,
                          false, // isVolatile,
                          (Size <= 32), // AlwaysInline if size <= 32
                          MachinePointerInfo(), MachinePointerInfo());

    ByValArgs.push_back(FIPtr);
  }

  // CALLSEQ_START will decrement the stack to reserve space
  Chain =
      DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(ArgsSize, true), DL);

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
      Arg = DAG.getNode(ISD::BITCAST, DL, VA.getLocVT(), Arg);
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
    SDValue StackPtr = DAG.getRegister(VectorProc::SP_REG, MVT::i32);
    SDValue PtrOff = DAG.getIntPtrConstant(VA.getLocMemOffset());
    PtrOff = DAG.getNode(ISD::ADD, DL, MVT::i32, StackPtr, PtrOff);
    MemOpChains.push_back(DAG.getStore(Chain, DL, Arg, PtrOff,
                                       MachinePointerInfo(), false, false, 0));
  }

  // Emit all stores, make sure the occur before any copies into physregs.
  if (!MemOpChains.empty()) {
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);
  }

  // Build a sequence of copy-to-reg nodes chained together with token
  // chain and flag operands which copy the outgoing args into registers.
  // The InFlag in necessary since all emitted instructions must be
  // stuck together.
  SDValue InFlag;
  for (const auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first,
                             Reg.second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // Get the function address.
  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), DL, MVT::i32);
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i32);

  // Returns a chain & a flag for retval copy to use
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  for (const auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first, Reg.second.getValueType()));

  // Add a register mask operand representing the call-preserved registers.
  const TargetRegisterInfo *TRI = getTargetMachine().getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(CLI.CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(CLI.DAG.getRegisterMask(Mask));

  if (InFlag.getNode())
    Ops.push_back(InFlag);

  Chain = DAG.getNode(VectorProcISD::CALL, DL, NodeTys, Ops);
  InFlag = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(ArgsSize, true),
                             DAG.getIntPtrConstant(0, true), InFlag, DL);
  InFlag = Chain.getValue(1);

  // The call has returned, handle return values
  SmallVector<CCValAssign, 16> RVLocs;
  CCState RVInfo(CallConv, isVarArg, DAG.getMachineFunction(), DAG.getTarget(),
                 RVLocs, *DAG.getContext());

  RVInfo.AnalyzeCallResult(Ins, RetCC_VectorProc32);

  // Copy all of the result registers out of their specified physreg.
  for (const auto &Loc : RVLocs) {
    Chain = DAG.getCopyFromReg(Chain, DL, Loc.getLocReg(),
                               Loc.getValVT(), InFlag).getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

unsigned VectorProcTargetLowering::getJumpTableEncoding() const {
  return MachineJumpTableInfo::EK_Inline;
}

VectorProcTargetLowering::VectorProcTargetLowering(TargetMachine &TM)
    : TargetLowering(TM, new VectorProcTargetObjectFile()) {
  Subtarget = &TM.getSubtarget<VectorProcSubtarget>();

  // Set up the register classes.
  addRegisterClass(MVT::i32, &VectorProc::GPR32RegClass);
  addRegisterClass(MVT::f32, &VectorProc::GPR32RegClass);
  addRegisterClass(MVT::v16i32, &VectorProc::VR512RegClass);
  addRegisterClass(MVT::v16f32, &VectorProc::VR512RegClass);

  setOperationAction(ISD::BUILD_VECTOR, MVT::v16f32, Custom);
  setOperationAction(ISD::BUILD_VECTOR, MVT::v16i32, Custom);
  setOperationAction(ISD::INSERT_VECTOR_ELT, MVT::v16f32, Custom);
  setOperationAction(ISD::INSERT_VECTOR_ELT, MVT::v16i32, Custom);
  setOperationAction(ISD::VECTOR_SHUFFLE, MVT::v16i32, Custom);
  setOperationAction(ISD::VECTOR_SHUFFLE, MVT::v16f32, Custom);
  setOperationAction(ISD::SCALAR_TO_VECTOR, MVT::v16i32, Custom);
  setOperationAction(ISD::SCALAR_TO_VECTOR, MVT::v16f32, Custom);
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::GlobalAddress, MVT::f32, Custom);
  setOperationAction(ISD::ConstantPool, MVT::i32, Custom);
  setOperationAction(ISD::ConstantPool, MVT::f32, Custom);
  setOperationAction(ISD::Constant, MVT::i32, Custom);
  setOperationAction(ISD::BlockAddress, MVT::i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::f32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::v16i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::v16f32, Custom);
  setOperationAction(ISD::FDIV, MVT::f32, Custom);
  setOperationAction(ISD::FDIV, MVT::v16f32, Custom);
  setOperationAction(ISD::BR_JT, MVT::Other, Custom);
  setOperationAction(ISD::FNEG, MVT::f32, Custom);
  setOperationAction(ISD::FNEG, MVT::v16f32, Custom);
  setOperationAction(ISD::SETCC, MVT::f32, Custom);
  setOperationAction(ISD::SETCC, MVT::v16f32, Custom);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i32, Custom);
  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i32, Custom);
  setOperationAction(ISD::UINT_TO_FP, MVT::i32, Custom);
  setOperationAction(ISD::FRAMEADDR, MVT::i32, Custom);
  setOperationAction(ISD::RETURNADDR, MVT::i32, Custom);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::v16i1, Custom);
  setOperationAction(ISD::VASTART, MVT::Other, Custom);

  setOperationAction(ISD::BR_CC, MVT::i32, Expand);
  setOperationAction(ISD::BR_CC, MVT::f32, Expand);
  setOperationAction(ISD::BRCOND, MVT::i32, Expand);
  setOperationAction(ISD::BRCOND, MVT::f32, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::CTPOP, MVT::i32, Expand);
  setOperationAction(ISD::SELECT, MVT::i32, Expand);
  setOperationAction(ISD::ROTL, MVT::i32, Expand);
  setOperationAction(ISD::ROTR, MVT::i32, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i32, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i32, Expand);
  setOperationAction(ISD::MULHU, MVT::i32, Expand);
  setOperationAction(ISD::MULHS, MVT::i32, Expand);
  setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
  setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);
  setOperationAction(ISD::FP_TO_UINT, MVT::i32, Expand);
  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i32, Expand);
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);
  setOperationAction(ISD::BSWAP, MVT::i32, Expand);
  setOperationAction(ISD::ADDC, MVT::i32, Expand);
  setOperationAction(ISD::ADDE, MVT::i32, Expand);
  setOperationAction(ISD::SUBC, MVT::i32, Expand);
  setOperationAction(ISD::SUBE, MVT::i32, Expand);
  setOperationAction(ISD::SRA_PARTS, MVT::i32, Expand);
  setOperationAction(ISD::SRL_PARTS, MVT::i32, Expand);
  setOperationAction(ISD::SHL_PARTS, MVT::i32, Expand);
  setOperationAction(ISD::VAARG, MVT::Other, Expand);
  setOperationAction(ISD::VACOPY, MVT::Other, Expand);
  setOperationAction(ISD::VAEND, MVT::Other, Expand);

  setOperationAction(ISD::ATOMIC_LOAD,       MVT::i32,    Expand);
  setOperationAction(ISD::ATOMIC_LOAD,       MVT::i64,    Expand);
  setOperationAction(ISD::ATOMIC_STORE,      MVT::i32,    Expand);
  setOperationAction(ISD::ATOMIC_STORE,      MVT::i64,    Expand);

  setInsertFencesForAtomic(true);

  setOperationAction(ISD::FABS,  MVT::f32, Legal);
  setOperationAction(ISD::FABS,  MVT::v16f32, Legal);

  setOperationAction(ISD::FFLOOR,  MVT::f32, Legal);
  setOperationAction(ISD::FFLOOR,  MVT::v16f32, Legal);

  //   Doesn't exist in LLVM
  // setOperationAction(ISD::FFRAC,  MVT::f32, Legal);
  // setOperationAction(ISD::FFRAC,  MVT::v16f32, Legal);

  // Hardware does not have an integer divider, so convert these to
  // library calls
  setOperationAction(ISD::UDIV, MVT::i32, Expand); // __udivsi3
  setOperationAction(ISD::UREM, MVT::i32, Expand); // __umodsi3
  setOperationAction(ISD::SDIV, MVT::i32, Expand); // __divsi3
  setOperationAction(ISD::SREM, MVT::i32, Expand); // __modsi3
  
  setOperationAction(ISD::FSQRT, MVT::f32, Expand); // sqrtf
  setOperationAction(ISD::FSIN, MVT::f32, Expand); // sinf
  setOperationAction(ISD::FCOS, MVT::f32, Expand); // cosf

  setStackPointerRegisterToSaveRestore(VectorProc::SP_REG);
  setMinFunctionAlignment(2);
  setSelectIsExpensive(); // Because there is no CMOV
  setIntDivIsCheap(false);
  setSchedulingPreference(Sched::RegPressure);

  computeRegisterProperties();
}

const char *VectorProcTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  case VectorProcISD::CALL:
    return "VectorProcISD::CALL";
  case VectorProcISD::RET_FLAG:
    return "VectorProcISD::RET_FLAG";
  case VectorProcISD::SPLAT:
    return "VectorProcISD::SPLAT";
  case VectorProcISD::SEL_COND_RESULT:
    return "VectorProcISD::SEL_COND_RESULT";
  case VectorProcISD::RECIPROCAL_EST:
    return "VectorProcISD::RECIPROCAL_EST";
  case VectorProcISD::BR_JT:
    return "VectorProcISD::BR_JT";
  case VectorProcISD::JT_WRAPPER:
    return "VectorProcISD::JT_WRAPPER";
  default:
    return nullptr;
  }
}

// Global addresses are stored in the per-function constant pool.
SDValue VectorProcTargetLowering::LowerGlobalAddress(SDValue Op,
                                                     SelectionDAG &DAG) const {
  SDLoc DL(Op);
  const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
  SDValue CPIdx = DAG.getTargetConstantPool(GV, MVT::i32);
  return DAG.getLoad(MVT::i32, DL, DAG.getEntryNode(), CPIdx,
                     MachinePointerInfo::getConstantPool(), false, false, false,
                     4);
}

SDValue VectorProcTargetLowering::LowerConstantPool(SDValue Op,
                                                    SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT PtrVT = Op.getValueType();
  ConstantPoolSDNode *CP = cast<ConstantPoolSDNode>(Op);
  SDValue Res;
  if (CP->isMachineConstantPoolEntry()) {
    Res = DAG.getTargetConstantPool(CP->getMachineCPVal(), PtrVT,
                                    CP->getAlignment());
  } else {
    Res =
        DAG.getTargetConstantPool(CP->getConstVal(), PtrVT, CP->getAlignment());
  }

  return Res;
}

SDValue VectorProcTargetLowering::LowerConstant(SDValue Op,
                                                SelectionDAG &DAG) const {
  SDLoc DL(Op);
  ConstantSDNode *C = cast<ConstantSDNode>(Op);

  // The size of the immediate field is determined by the instruction format and
  // whether a mask is present.  At this level of the tree, we cannot know that,
  // so we use the smallest size.
  const int kMaxImmediateSize = 13;

  if (C->getAPIntValue().abs().ult((1 << (kMaxImmediateSize - 1)) - 1)) {
    // Don't need to convert to constant pool reference.  This will fit in
    // the immediate field of a single instruction, sign extended.
    return SDValue();
  }

  SDValue CPIdx = DAG.getConstantPool(C->getConstantIntValue(), MVT::i32);
  return DAG.getLoad(MVT::i32, DL, DAG.getEntryNode(), CPIdx,
                     MachinePointerInfo::getConstantPool(), false, false, false,
                     4);
}

SDValue VectorProcTargetLowering::LowerBlockAddress(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  const BlockAddress *BA = cast<BlockAddressSDNode>(Op)->getBlockAddress();
  SDValue CPIdx = DAG.getTargetConstantPool(BA, MVT::i32);
  return DAG.getLoad(MVT::i32, DL, DAG.getEntryNode(), CPIdx,
                     MachinePointerInfo::getConstantPool(), false, false, false,
                     4);
}

SDValue VectorProcTargetLowering::LowerVASTART(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  MachineFunction &MF = DAG.getMachineFunction();
  VectorProcMachineFunctionInfo *VFI = MF.getInfo<VectorProcMachineFunctionInfo>();
  SDValue FI = DAG.getFrameIndex(VFI->getVarArgsFrameIndex(),
                                 getPointerTy());
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), DL, FI, Op.getOperand(1),
                      MachinePointerInfo(SV), false, false, 0);
}

/// isSplatVector - Returns true if N is a BUILD_VECTOR node whose elements are
/// all the same.
static bool isSplatVector(SDNode *N) {
  SDValue SplatValue = N->getOperand(0);
  for (unsigned i = 1, e = N->getNumOperands(); i != e; ++i)
    if (N->getOperand(i) != SplatValue)
      return false;

  return true;
}

static bool isZero(SDValue V) {
  ConstantSDNode *C = dyn_cast<ConstantSDNode>(V);
  return C && C->isNullValue();
}

SDValue VectorProcTargetLowering::LowerBUILD_VECTOR(SDValue Op,
                                                    SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);

  if (isSplatVector(Op.getNode())) {
    // This is a constant node that is duplicated to all lanes.
    // Convert it to a SPLAT node.
    return DAG.getNode(VectorProcISD::SPLAT, DL, VT, Op.getOperand(0));
  }

  return SDValue(); // Expand
}

// SCALAR_TO_VECTOR loads the scalar register into lane 0 of the register.
// The rest of the lanes are undefined.  For simplicity, we just load the same
// value into all lanes.
SDValue
VectorProcTargetLowering::LowerSCALAR_TO_VECTOR(SDValue Op,
                                                SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);
  return DAG.getNode(VectorProcISD::SPLAT, DL, VT, Op.getOperand(0));
}

// (VECTOR, VAL, IDX)
// Convert to a move with a mask (0x8000 >> IDX) and a splatted scalar operand.
SDValue
VectorProcTargetLowering::LowerINSERT_VECTOR_ELT(SDValue Op,
                                                 SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);

  // This could also be (1 << (15 - index)), which avoids the load of 0x8000
  // but requires more operations.
  SDValue Mask =
      DAG.getNode(ISD::SRL, DL, MVT::i32, DAG.getConstant(0x8000, MVT::i32),
                  Op.getOperand(2));
  SDValue Splat = DAG.getNode(VectorProcISD::SPLAT, DL, VT, Op.getOperand(1));
  return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, VT,
                     DAG.getConstant(Intrinsic::vp_vector_mixi, MVT::i32), Mask,
                     Splat, Op.getOperand(0));
}

bool VectorProcTargetLowering::isShuffleMaskLegal(const SmallVectorImpl<int> &M,
                                                  EVT VT) const {
  if (M.size() != 16)
    return false;

  for (int val : M) {
    if (val != 0)
      return false;
  }

  return true;
}

//
// Look for patterns that built splats.  isShuffleMaskLegal should ensure this
// will only be called with splat masks, but I don't know if there are edge cases 
// where it will still be called.  Perhaps need to check explicitly (note that the 
// shuffle mask doesn't appear to be an operand, but must be accessed by casting the 
// SDNode and using a separate accessor).
//
SDValue VectorProcTargetLowering::LowerVECTOR_SHUFFLE(SDValue Op,
                                                      SelectionDAG &DAG) const {
  MVT VT = Op.getValueType().getSimpleVT();
  SDLoc DL(Op);

  // Using shufflevector to build a splat like this:
  // %vector = shufflevector <16 x i32> %single, <16 x i32> (don't care),
  //                       <16 x i32> zeroinitializer

  // %single = insertelement <16 x i32> (don't care), i32 %value, i32 0
  if (Op.getOperand(0).getOpcode() == ISD::INSERT_VECTOR_ELT &&
      isZero(Op.getOperand(0).getOperand(2)))
    return DAG.getNode(VectorProcISD::SPLAT, DL, VT,
                       Op.getOperand(0).getOperand(1));

  // %single = scalar_to_vector i32 %b
  if (Op.getOperand(0).getOpcode() == ISD::SCALAR_TO_VECTOR)
    return DAG.getNode(VectorProcISD::SPLAT, DL, VT,
                       Op.getOperand(0).getOperand(0));

  return SDValue();
}

// This architecture does not support conditional moves for scalar registers.
// We must convert this into a set of conditional branches.  We do this by
// creating a pseudo-instruction SEL_COND_RESULT, which will later be
// transformed.
SDValue VectorProcTargetLowering::LowerSELECT_CC(SDValue Op,
                                                 SelectionDAG &DAG) const {
  SDLoc DL(Op);
  EVT Ty = Op.getOperand(0).getValueType();
  SDValue Pred =
      DAG.getNode(ISD::SETCC, DL, getSetCCResultType(*DAG.getContext(), Ty),
                  Op.getOperand(0), Op.getOperand(1), Op.getOperand(4));

  return DAG.getNode(VectorProcISD::SEL_COND_RESULT, DL, Op.getValueType(),
                     Pred, Op.getOperand(2), Op.getOperand(3));
}

// There is no native floating point division, but we can convert this to a
// reciprocal/multiply operation.  If the first parameter is constant 1.0, then
// just a reciprocal will suffice.
SDValue VectorProcTargetLowering::LowerFDIV(SDValue Op,
                                            SelectionDAG &DAG) const {
  SDLoc DL(Op);

  EVT Type = Op.getOperand(1).getValueType();

  SDValue Two = DAG.getConstantFP(2.0, Type);
  SDValue Denominator = Op.getOperand(1);
  SDValue Estimate =
      DAG.getNode(VectorProcISD::RECIPROCAL_EST, DL, Type, Denominator);

  // Perform a series of Newton Raphson refinements to determine 1/divisor. Each 
  // iteration doubles the precision of the result. The initial estimate has 6 bits 
  // of precision, so two iterations results in 24 bits, which is larger than the 
  // (23 bit) significand.
  for (int i = 0; i < 2; i++) {
    // Trial = x * Estimate (ideally, x * 1/x should be 1.0)
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

// Branch using jump table (used for switch statements)
SDValue VectorProcTargetLowering::LowerBR_JT(SDValue Op,
                                             SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  SDValue Table = Op.getOperand(1);
  SDValue Index = Op.getOperand(2);
  SDLoc DL(Op);
  EVT PTy = getPointerTy();
  JumpTableSDNode *JT = cast<JumpTableSDNode>(Table);
  SDValue JTI = DAG.getTargetJumpTable(JT->getIndex(), PTy);
  SDValue TableWrapper = DAG.getNode(VectorProcISD::JT_WRAPPER, DL, PTy, JTI);
  SDValue TableMul =
      DAG.getNode(ISD::MUL, DL, PTy, Index, DAG.getConstant(4, PTy));
  SDValue JTAddr = DAG.getNode(ISD::ADD, DL, PTy, TableWrapper, TableMul);
  return DAG.getNode(VectorProcISD::BR_JT, DL, MVT::Other, Chain, JTAddr, JTI);
}

// There is no native FNEG instruction, so we emulate it by XORing with
// 0x80000000
SDValue VectorProcTargetLowering::LowerFNEG(SDValue Op,
                                            SelectionDAG &DAG) const {
  SDLoc DL(Op);
  MVT ResultVT = Op.getValueType().getSimpleVT();
  MVT IntermediateVT = ResultVT.isVector() ? MVT::v16i32 : MVT::i32;

  SDValue rhs = DAG.getConstant(0x80000000, MVT::i32);
  SDValue iconv;
  if (ResultVT.isVector())
    rhs = DAG.getNode(VectorProcISD::SPLAT, DL, MVT::v16i32, rhs);

  iconv = DAG.getNode(ISD::BITCAST, DL, IntermediateVT, Op.getOperand(0));
  SDValue flipped = DAG.getNode(ISD::XOR, DL, IntermediateVT, iconv, rhs);
  return DAG.getNode(ISD::BITCAST, DL, ResultVT, flipped);
}

// Handle unsupported floating point operations: unordered comparisons
// and equality.
SDValue VectorProcTargetLowering::LowerSETCC(SDValue Op,
                                             SelectionDAG &DAG) const {
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(2))->get();
  ISD::CondCode NewCode;
  SDLoc DL(Op);

  switch (CC) {
  default:
    return Op; // No change

  // Convert unordered comparisons to ordered.
  // An ordered comparison is always false if either operand is NaN
  // An unordered comparision is always true if either operand is NaN
  // The hardware implements ordered comparisons.  Clang generally emits
  // ordered comparisons.
  //
  // XXX In order to be correct, we should probably emit code that explicitly
  // checks for NaN and forces the result to true.
  //
  case ISD::SETUGT:
    NewCode = ISD::SETOGT;
    break;
  case ISD::SETUGE:
    NewCode = ISD::SETOGE;
    break;
  case ISD::SETULT:
    NewCode = ISD::SETOLT;
    break;
  case ISD::SETULE:
    NewCode = ISD::SETOLE;
    break;

  // Change don't care floating point comparisons to the default CPU Type
  case ISD::SETGT:
    NewCode = ISD::SETOGT;
    break;
  case ISD::SETGE:
    NewCode = ISD::SETOGE;
    break;
  case ISD::SETLT:
    NewCode = ISD::SETOLT;
    break;
  case ISD::SETLE:
    NewCode = ISD::SETOLE;
    break;

  // Note: there is no floating point eq/ne.  Just use integer
  // forms
  case ISD::SETUEQ:
  case ISD::SETOEQ:
    NewCode = ISD::SETEQ;
    break;

  case ISD::SETUNE:
  case ISD::SETONE:
    NewCode = ISD::SETNE;
    break;
  }

  SDValue Op0 = Op.getOperand(0);
  SDValue Op1 = Op.getOperand(1);
  if (NewCode == ISD::SETEQ || NewCode == ISD::SETNE) {
    // Need to bitcast so we will match
    Op0 = DAG.getNode(ISD::BITCAST, DL,
                      Op0.getValueType().isVector() ? MVT::v16i32 : MVT::i32,
                      Op0);
    Op1 = DAG.getNode(ISD::BITCAST, DL,
                      Op1.getValueType().isVector() ? MVT::v16i32 : MVT::i32,
                      Op1);
  }

  return DAG.getNode(ISD::SETCC, DL, Op.getValueType().getSimpleVT(), Op0, Op1,
                     DAG.getCondCode(NewCode));
}

SDValue
VectorProcTargetLowering::LowerCTLZ_ZERO_UNDEF(SDValue Op,
                                               SelectionDAG &DAG) const {
  SDLoc DL(Op);
  return DAG.getNode(ISD::CTLZ, DL, Op.getValueType(), Op.getOperand(0));
}

SDValue
VectorProcTargetLowering::LowerCTTZ_ZERO_UNDEF(SDValue Op,
                                               SelectionDAG &DAG) const {
  SDLoc DL(Op);
  return DAG.getNode(ISD::CTTZ, DL, Op.getValueType(), Op.getOperand(0));
}

//
// The architecture only supports signed integer to floating point.  If the
// source value is negative (when treated as signed), then add UINT_MAX to the
// resulting floating point value to adjust it.
// This is a simpler version of SelectionDAGLegalize::ExpandLegalINT_TO_FP.
// I've done a custom expansion because the default version uses arithmetic
// with constant pool symbols, and that gets clobbered (see comments in
// VectorProcMCInstLower::Lower)
//
SDValue VectorProcTargetLowering::LowerUINT_TO_FP(SDValue Op,
                                                  SelectionDAG &DAG) const {
  SDLoc DL(Op);

  SDValue RVal = Op.getOperand(0);
  SDValue SignedVal = DAG.getNode(ISD::SINT_TO_FP, DL, MVT::f32, RVal);
  Constant *FudgeFactor =
      ConstantInt::get(Type::getInt32Ty(*DAG.getContext()),
                       0x4f800000); // UINT_MAX in float format
  SDValue CPIdx = DAG.getConstantPool(FudgeFactor, MVT::f32);
  SDValue FudgeInReg = DAG.getLoad(MVT::f32, DL, DAG.getEntryNode(), CPIdx,
                                   MachinePointerInfo::getConstantPool(), false,
                                   false, false, 4);
  SDValue IsNegative =
      DAG.getSetCC(DL, getSetCCResultType(*DAG.getContext(), MVT::i32), RVal,
                   DAG.getConstant(0, MVT::i32), ISD::SETLT);
  SDValue Adjusted =
      DAG.getNode(ISD::FADD, DL, MVT::f32, SignedVal, FudgeInReg);

  return DAG.getNode(VectorProcISD::SEL_COND_RESULT, DL, MVT::f32, IsNegative,
                     Adjusted, SignedVal);
}

SDValue VectorProcTargetLowering::LowerFRAMEADDR(SDValue Op, SelectionDAG &DAG) const {
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Frame address can only be determined for current frame.");

  SDLoc DL(Op);
  MachineFrameInfo *MFI = DAG.getMachineFunction().getFrameInfo();
  MFI->setFrameAddressIsTaken(true);
  EVT VT = Op.getValueType();
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, VectorProc::FP_REG, VT);
}

SDValue VectorProcTargetLowering::LowerRETURNADDR(SDValue Op, SelectionDAG &DAG) const {
  if (verifyReturnAddressArgumentIsConstant(Op, DAG))
    return SDValue();

  // check the depth
  assert((cast<ConstantSDNode>(Op.getOperand(0))->getZExtValue() == 0) &&
         "Return address can be determined only for current frame.");

  SDLoc DL(Op);
  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  MVT VT = Op.getSimpleValueType();
  MFI->setReturnAddressIsTaken(true);

  // Return RA, which contains the return address. Mark it an implicit live-in.
  unsigned Reg = MF.addLiveIn(VectorProc::LINK_REG, getRegClassFor(VT));
  return DAG.getCopyFromReg(DAG.getEntryNode(), DL, Reg, VT);
}

static Intrinsic::ID intrinsicForVectorCompare(ISD::CondCode CC, bool isFloat) {
  if (isFloat)
  {
    switch (CC)
    {
      case ISD::SETOEQ:
      case ISD::SETUEQ:
      case ISD::SETEQ:
        return Intrinsic::vp_mask_cmpf_eq;

      case ISD::SETONE:
      case ISD::SETUNE:
      case ISD::SETNE:
        return Intrinsic::vp_mask_cmpf_ne;

      case ISD::SETOGT:
      case ISD::SETUGT:
      case ISD::SETGT:
        return Intrinsic::vp_mask_cmpf_gt;

      case ISD::SETOGE:
      case ISD::SETUGE:
      case ISD::SETGE:
        return Intrinsic::vp_mask_cmpf_ge;

      case ISD::SETOLT:
      case ISD::SETULT:
      case ISD::SETLT:
        return Intrinsic::vp_mask_cmpf_lt;

      case ISD::SETOLE:
      case ISD::SETULE:
      case ISD::SETLE:
        return Intrinsic::vp_mask_cmpf_le;

      default:
        ; // falls through
    }    
  }
  else
  {
    switch (CC)
    {
      case ISD::SETUEQ:
      case ISD::SETEQ:
        return Intrinsic::vp_mask_cmpi_eq;

      case ISD::SETUNE:
      case ISD::SETNE:
        return Intrinsic::vp_mask_cmpi_ne;

      case ISD::SETUGT:
        return Intrinsic::vp_mask_cmpi_ugt;

      case ISD::SETGT:
        return Intrinsic::vp_mask_cmpi_sgt;

      case ISD::SETUGE:
        return Intrinsic::vp_mask_cmpi_uge;

      case ISD::SETGE:
        return Intrinsic::vp_mask_cmpi_sge;

      case ISD::SETULT:
        return Intrinsic::vp_mask_cmpi_ult;

      case ISD::SETLT:
        return Intrinsic::vp_mask_cmpi_slt;

      case ISD::SETULE:
        return Intrinsic::vp_mask_cmpi_ule;

      case ISD::SETLE:
        return Intrinsic::vp_mask_cmpi_sle;
        
      default:
        ; // falls through
    }    
  }

  llvm_unreachable("unhandled compare code");
}

//
// This may be used to expand a vector comparison result into a vector.  Normally,
// vector compare results are a bitmask, so we need to do a predicated transfer
// to expand it.
// Note that clang seems to assume a vector lane should have 0xffffffff when the 
// result is true when folding constants, so we use that value here to be consistent,
// even though that is not what a scalar compare would do.
//
SDValue VectorProcTargetLowering::LowerSIGN_EXTEND_INREG(SDValue Op, 
                                                         SelectionDAG &DAG) const {
  SDValue SetCcOp = Op.getOperand(0);
  if (SetCcOp.getOpcode() != ISD::SETCC)
    return SDValue();

  SDLoc DL(Op);
  Intrinsic::ID intrinsic = intrinsicForVectorCompare(cast<CondCodeSDNode>(
                                                      SetCcOp.getOperand(2))->get(),
                                                      SetCcOp.getOperand(0).getValueType()
                                                      .getSimpleVT().isFloatingPoint());

  SDValue FalseVal = DAG.getNode(VectorProcISD::SPLAT, DL, MVT::v16i32,
                             DAG.getConstant(0, MVT::i32));
  SDValue TrueVal = DAG.getNode(VectorProcISD::SPLAT, DL, MVT::v16i32, 
                            DAG.getConstant(0xffffffff, MVT::i32));
  SDValue Mask = DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, MVT::i32,
                             DAG.getConstant(intrinsic, MVT::i32), 
                             SetCcOp.getOperand(0), SetCcOp.getOperand(1));
  return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, DL, MVT::v16i32,
                     DAG.getConstant(Intrinsic::vp_vector_mixi, MVT::i32), Mask,
                     TrueVal, FalseVal);
}

SDValue VectorProcTargetLowering::LowerOperation(SDValue Op,
                                                 SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::VECTOR_SHUFFLE:
    return LowerVECTOR_SHUFFLE(Op, DAG);
  case ISD::BUILD_VECTOR:
    return LowerBUILD_VECTOR(Op, DAG);
  case ISD::INSERT_VECTOR_ELT:
    return LowerINSERT_VECTOR_ELT(Op, DAG);
  case ISD::SCALAR_TO_VECTOR:
    return LowerSCALAR_TO_VECTOR(Op, DAG);
  case ISD::GlobalAddress:
    return LowerGlobalAddress(Op, DAG);
  case ISD::BlockAddress:
    return LowerBlockAddress(Op, DAG);
  case ISD::ConstantPool:
    return LowerConstantPool(Op, DAG);
  case ISD::Constant:
    return LowerConstant(Op, DAG);
  case ISD::SELECT_CC:
    return LowerSELECT_CC(Op, DAG);
  case ISD::FDIV:
    return LowerFDIV(Op, DAG);
  case ISD::BR_JT:
    return LowerBR_JT(Op, DAG);
  case ISD::FNEG:
    return LowerFNEG(Op, DAG);
  case ISD::SETCC:
    return LowerSETCC(Op, DAG);
  case ISD::CTLZ_ZERO_UNDEF:
    return LowerCTLZ_ZERO_UNDEF(Op, DAG);
  case ISD::CTTZ_ZERO_UNDEF:
    return LowerCTTZ_ZERO_UNDEF(Op, DAG);
  case ISD::UINT_TO_FP:
    return LowerUINT_TO_FP(Op, DAG);
  case ISD::FRAMEADDR:
    return LowerFRAMEADDR(Op, DAG);
  case ISD::RETURNADDR:  
    return LowerRETURNADDR(Op, DAG);
  case ISD::SIGN_EXTEND_INREG:
    return LowerSIGN_EXTEND_INREG(Op, DAG);
  case ISD::VASTART:
    return LowerVASTART(Op, DAG);
  default:
    llvm_unreachable("Should not custom lower this!");
  }
}

EVT VectorProcTargetLowering::getSetCCResultType(LLVMContext &Context,
                                                 EVT VT) const {
  if (!VT.isVector())
    return MVT::i32;

  return VT.changeVectorElementTypeToInteger();
}

MachineBasicBlock *VectorProcTargetLowering::EmitInstrWithCustomInserter(
    MachineInstr *MI, MachineBasicBlock *BB) const {
  switch (MI->getOpcode()) {
  case VectorProc::SELECTI:
  case VectorProc::SELECTF:
  case VectorProc::SELECTVI:
  case VectorProc::SELECTVF:
    return EmitSelectCC(MI, BB);

  case VectorProc::ATOMIC_LOAD_ADDR:
    return EmitAtomicBinary(MI, BB, VectorProc::ADDISSS);

  case VectorProc::ATOMIC_LOAD_ADDI:
    return EmitAtomicBinary(MI, BB, VectorProc::ADDISSI);

  case VectorProc::ATOMIC_LOAD_SUBR:
    return EmitAtomicBinary(MI, BB, VectorProc::SUBISSS);

  case VectorProc::ATOMIC_LOAD_SUBI:
    return EmitAtomicBinary(MI, BB, VectorProc::SUBISSI);

  case VectorProc::ATOMIC_LOAD_ANDR:
    return EmitAtomicBinary(MI, BB, VectorProc::ANDSSS);

  case VectorProc::ATOMIC_LOAD_ANDI:
    return EmitAtomicBinary(MI, BB, VectorProc::ANDSSI);

  case VectorProc::ATOMIC_LOAD_ORR:
    return EmitAtomicBinary(MI, BB, VectorProc::ORSSS);

  case VectorProc::ATOMIC_LOAD_ORI:
    return EmitAtomicBinary(MI, BB, VectorProc::ORSSI);

  case VectorProc::ATOMIC_LOAD_XORR:
    return EmitAtomicBinary(MI, BB, VectorProc::XORSSS);

  case VectorProc::ATOMIC_LOAD_XORI:
    return EmitAtomicBinary(MI, BB, VectorProc::XORSSI);

  // XXX ATOMIC_LOAD_NAND is not supported

  case VectorProc::ATOMIC_SWAP:
    return EmitAtomicBinary(MI, BB, 0);
    
  case VectorProc::ATOMIC_CMP_SWAP:
    return EmitAtomicCmpSwap(MI, BB);

  default:
    llvm_unreachable("unknown atomic operation");
  }
}

MachineBasicBlock *
VectorProcTargetLowering::EmitSelectCC(MachineInstr *MI,
                                       MachineBasicBlock *BB) const {
  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
  DebugLoc DL = MI->getDebugLoc();

  // The instruction we are replacing is SELECTI (Dest, predicate, trueval,
  // falseval)

  // To "insert" a SELECT_CC instruction, we actually have to rewrite it into a
  // diamond control-flow pattern.  The incoming instruction knows the
  // destination vreg to set, the condition code register to branch on, the
  // true/false values to select between, and a branch opcode to use.
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = BB;
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

  BuildMI(BB, DL, TII->get(VectorProc::BTRUE))
      .addReg(MI->getOperand(1).getReg())
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

  BuildMI(*BB, BB->begin(), DL, TII->get(VectorProc::PHI),
          MI->getOperand(0).getReg())
      .addReg(MI->getOperand(2).getReg())
      .addMBB(ThisMBB)
      .addReg(MI->getOperand(3).getReg())
      .addMBB(Copy0MBB);

  MI->eraseFromParent(); // The pseudo instruction is gone now.
  return BB;
}

MachineBasicBlock *
VectorProcTargetLowering::EmitAtomicBinary(MachineInstr *MI, MachineBasicBlock *BB,
                                        unsigned Opcode) const {
  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();

  unsigned Dest = MI->getOperand(0).getReg();
  unsigned Ptr = MI->getOperand(1).getReg();
  DebugLoc DL = MI->getDebugLoc();
  MachineRegisterInfo &MRI = BB->getParent()->getRegInfo();
  unsigned OldValue = MRI.createVirtualRegister(&VectorProc::GPR32RegClass);
  unsigned Success = MRI.createVirtualRegister(&VectorProc::GPR32RegClass);

  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction *MF = BB->getParent();
  MachineFunction::iterator It = BB;
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
  BuildMI(BB, DL, TII->get(VectorProc::LOAD_SYNC), OldValue).addReg(Ptr).addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::MOVESS), Dest).addReg(OldValue);
  
  unsigned NewValue;
  if (Opcode != 0)
  {
    // Perform an operation
    NewValue = MRI.createVirtualRegister(&VectorProc::GPR32RegClass);
    if (MI->getOperand(2).getType() == MachineOperand::MO_Register)
      BuildMI(BB, DL, TII->get(Opcode), NewValue).addReg(OldValue).addReg(MI->getOperand(2).getReg());
    else if (MI->getOperand(2).getType() == MachineOperand::MO_Immediate)
      BuildMI(BB, DL, TII->get(Opcode), NewValue).addReg(OldValue).addImm(MI->getOperand(2).getImm());
    else
      llvm_unreachable("Unknown operand type");
  }
  else
    NewValue = OldValue; // This is just swap: use old value
  
  BuildMI(BB, DL, TII->get(VectorProc::STORE_SYNC), Success)
      .addReg(NewValue)
      .addReg(Ptr)
      .addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::BFALSE)).addReg(Success).addMBB(LoopMBB);
  BB->addSuccessor(LoopMBB);
  BB->addSuccessor(ExitMBB);

  //  ExitMBB:
  BB = ExitMBB;

  MI->eraseFromParent(); // The instruction is gone now.

  return BB;
}

MachineBasicBlock *
VectorProcTargetLowering::EmitAtomicCmpSwap(MachineInstr *MI,
                                            MachineBasicBlock *BB) const {
  MachineFunction *MF = BB->getParent();
  MachineRegisterInfo &RegInfo = MF->getRegInfo();
  const TargetRegisterClass *RC = getRegClassFor(MVT::i32);
  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
  DebugLoc DL = MI->getDebugLoc();

  unsigned Dest = MI->getOperand(0).getReg();
  unsigned Ptr = MI->getOperand(1).getReg();
  unsigned OldVal = MI->getOperand(2).getReg();
  unsigned NewVal = MI->getOperand(3).getReg();

  unsigned Success = RegInfo.createVirtualRegister(RC);
  unsigned CmpResult = RegInfo.createVirtualRegister(RC);

  // insert new blocks after the current block
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineBasicBlock *Loop1MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *Loop2MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *ExitMBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineFunction::iterator It = BB;
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
  BuildMI(BB, DL, TII->get(VectorProc::LOAD_SYNC), Dest).addReg(Ptr).addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::SNESISS), CmpResult)
      .addReg(Dest)
      .addReg(OldVal);
  BuildMI(BB, DL, TII->get(VectorProc::BTRUE)).addReg(CmpResult).addMBB(
      ExitMBB);

  // Loop2MBB:
  //   move success, newval			; need a temporary because
  //   store.sync success, 0(Ptr)	; store.sync will clobber success
  //   bfalse success, Loop1MBB
  BB = Loop2MBB;
  BuildMI(BB, DL, TII->get(VectorProc::STORE_SYNC), Success)
      .addReg(NewVal)
      .addReg(Ptr)
      .addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::BFALSE)).addReg(Success).addMBB(
      Loop1MBB);

  MI->eraseFromParent(); // The instruction is gone now.

  return ExitMBB;
}

//===----------------------------------------------------------------------===//
//                         VectorProc Inline Assembly Support
//===----------------------------------------------------------------------===//

/// getConstraintType - Given a constraint letter, return the Type of
/// constraint it is for this target.
VectorProcTargetLowering::ConstraintType
VectorProcTargetLowering::getConstraintType(const std::string &Constraint)
    const {
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
VectorProcTargetLowering::getRegForInlineAsmConstraint(
    const std::string &Constraint, MVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 's':
    case 'r':
      return std::make_pair(0U, &VectorProc::GPR32RegClass);

    case 'v':
      return std::make_pair(0U, &VectorProc::VR512RegClass);
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

bool VectorProcTargetLowering::isOffsetFoldingLegal(
    const GlobalAddressSDNode *GA) const {
  // The VectorProc target isn't yet aware of offsets.
  return false;
}
