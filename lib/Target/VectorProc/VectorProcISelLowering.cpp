//===-- VectorProcISelLowering.cpp - VectorProc DAG Lowering Implementation ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the interfaces that VectorProc uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "isel"
#include "VectorProcISelLowering.h"
#include "VectorProcMachineFunctionInfo.h"
#include "VectorProcTargetMachine.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAG.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Debug.h"
using namespace llvm;


//===----------------------------------------------------------------------===//
// Calling Convention Implementation
//===----------------------------------------------------------------------===//

static bool CC_VectorProc_Assign_SRet(unsigned &ValNo, MVT &ValVT,
                                 MVT &LocVT, CCValAssign::LocInfo &LocInfo,
                                 ISD::ArgFlagsTy &ArgFlags, CCState &State)
{
  assert (ArgFlags.isSRet());

  //Assign SRet argument
  State.addLoc(CCValAssign::getCustomMem(ValNo, ValVT,
                                         0,
                                         LocVT, LocInfo));
  return true;
}


#include "VectorProcGenCallingConv.inc"

SDValue
VectorProcTargetLowering::LowerReturn(SDValue Chain,
                                 CallingConv::ID CallConv, bool IsVarArg,
                                 const SmallVectorImpl<ISD::OutputArg> &Outs,
                                 const SmallVectorImpl<SDValue> &OutVals,
                                 DebugLoc DL, SelectionDAG &DAG) const {
  MachineFunction &MF = DAG.getMachineFunction();

  // CCValAssign - represent the assignment of the return value to locations.
  SmallVector<CCValAssign, 16> RVLocs;

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(),
                 DAG.getTarget(), RVLocs, *DAG.getContext());

  // Analyze return values.
  CCInfo.AnalyzeReturn(Outs, RetCC_VectorProc32);

  SDValue Flag;
  SmallVector<SDValue, 4> RetOps(1, Chain);
  // Make room for the return address offset.
  RetOps.push_back(SDValue());

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(),
                             OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together with flags.
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  unsigned RetAddrOffset = 8; //Call Inst + Delay Slot
  // If the function returns a struct, copy the SRetReturnReg to I0
  if (MF.getFunction()->hasStructRetAttr()) {
    VectorProcMachineFunctionInfo *SFI = MF.getInfo<VectorProcMachineFunctionInfo>();
    unsigned Reg = SFI->getSRetReturnReg();
    if (!Reg)
      llvm_unreachable("sret virtual register not created in the entry block");
    SDValue Val = DAG.getCopyFromReg(Chain, DL, Reg, getPointerTy());
    Chain = DAG.getCopyToReg(Chain, DL, SP::S0, Val, Flag);
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(SP::S0, getPointerTy()));
    RetAddrOffset = 12; // CallInst + Delay Slot + Unimp
  }

  RetOps[0] = Chain;  // Update chain.
  RetOps[1] = DAG.getConstant(RetAddrOffset, MVT::i32);

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(SPISD::RET_FLAG, DL, MVT::Other,
                     &RetOps[0], RetOps.size());
}


SDValue VectorProcTargetLowering::
LowerFormalArguments(SDValue Chain,
                        CallingConv::ID CallConv,
                        bool isVarArg,
                        const SmallVectorImpl<ISD::InputArg> &Ins,
                        DebugLoc dl,
                        SelectionDAG &DAG,
                        SmallVectorImpl<SDValue> &InVals) const {
  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();
  VectorProcMachineFunctionInfo *FuncInfo = MF.getInfo<VectorProcMachineFunctionInfo>();

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(),
                 getTargetMachine(), ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_VectorProc32);

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    CCValAssign &VA = ArgLocs[i];

    if (i == 0  && Ins[i].Flags.isSRet()) {
      //Get SRet from [%fp+64]
      int FrameIdx = MF.getFrameInfo()->CreateFixedObject(4, 64, true);
      SDValue FIPtr = DAG.getFrameIndex(FrameIdx, MVT::i32);
      SDValue Arg = DAG.getLoad(MVT::i32, dl, Chain, FIPtr,
                                MachinePointerInfo(),
                                false, false, false, 0);
      InVals.push_back(Arg);
      continue;
    }

	if (VA.isRegLoc()) {
		// Is in a register
		EVT RegVT = VA.getLocVT();
		const TargetRegisterClass *RC;
		
		if (RegVT == MVT::i32 || RegVT == MVT::f32)
			RC = &SP::ScalarRegRegClass;
		else if (RegVT == MVT::v16i32 || RegVT == MVT::v16f32)
			RC = &SP::VectorRegRegClass;
		else
			llvm_unreachable("Unsupported formal argument type");

		unsigned VReg = RegInfo.createVirtualRegister(RC);
		MF.getRegInfo().addLiveIn(VA.getLocReg(), VReg);
		SDValue Arg = DAG.getCopyFromReg(Chain, dl, VReg, VA.getLocVT());
		InVals.push_back(Arg);
		continue;
	}

	// Else is on the stack
    assert(VA.isMemLoc());

	// 
    int FI = MF.getFrameInfo()->CreateFixedObject(VA.getValVT().getSizeInBits() / 8,
                                                  VA.getLocMemOffset(),
                                                  true);
    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy());
    SDValue Load ;
    if (VA.getValVT() == MVT::i32 || VA.getValVT() == MVT::f32
    	|| VA.getValVT() == MVT::v16i32) {
      Load = DAG.getLoad(VA.getValVT(), dl, Chain, FIPtr,
                         MachinePointerInfo(),
                         false, false, false, 0);
    } else {
    	// XXX need to handle vector load...
    
      ISD::LoadExtType LoadOp = ISD::SEXTLOAD;
      unsigned Offset = 4-std::max(1U, VA.getValVT().getSizeInBits()/8);
      FIPtr = DAG.getNode(ISD::ADD, dl, MVT::i32, FIPtr,
                          DAG.getConstant(Offset, MVT::i32));
      Load = DAG.getExtLoad(LoadOp, dl, MVT::i32, Chain, FIPtr,
                            MachinePointerInfo(),
                            VA.getValVT(), false, false,0);
      Load = DAG.getNode(ISD::TRUNCATE, dl, VA.getValVT(), Load);
    }
    InVals.push_back(Load);
  }

  if (MF.getFunction()->hasStructRetAttr()) {
    //Copy the SRet Argument to SRetReturnReg
    VectorProcMachineFunctionInfo *SFI = MF.getInfo<VectorProcMachineFunctionInfo>();
    unsigned Reg = SFI->getSRetReturnReg();
    if (!Reg) {
      Reg = MF.getRegInfo().createVirtualRegister(&SP::ScalarRegRegClass);
      SFI->setSRetReturnReg(Reg);
    }
    SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), dl, Reg, InVals[0]);
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, Copy, Chain);
  }

  // Store remaining ArgRegs to the stack if this is a varargs function.
  if (isVarArg) {
  	llvm_unreachable("variable arguments not implemented yet");
  }

  return Chain;
}


SDValue
VectorProcTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                  SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG                     = CLI.DAG;
  DebugLoc &dl                          = CLI.DL;
  SmallVector<ISD::OutputArg, 32> &Outs = CLI.Outs;
  SmallVector<SDValue, 32> &OutVals     = CLI.OutVals;
  SmallVector<ISD::InputArg, 32> &Ins   = CLI.Ins;
  SDValue Chain                         = CLI.Chain;
  SDValue Callee                        = CLI.Callee;
  bool &isTailCall                      = CLI.IsTailCall;
  CallingConv::ID CallConv              = CLI.CallConv;
  bool isVarArg                         = CLI.IsVarArg;

  isTailCall = false;

  // Analyze operands of the call, assigning locations to each operand.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(),
                 DAG.getTarget(), ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_VectorProc32);

  // Get the size of the outgoing arguments stack space requirement.
  unsigned ArgsSize = CCInfo.getNextStackOffset();

  // Keep stack frames 64-byte aligned.
  ArgsSize = (ArgsSize+63) & ~63;

  MachineFrameInfo *MFI = DAG.getMachineFunction().getFrameInfo();

  //Create local copies for byval args.
  SmallVector<SDValue, 8> ByValArgs;
  for (unsigned i = 0,  e = Outs.size(); i != e; ++i) {
    ISD::ArgFlagsTy Flags = Outs[i].Flags;
    if (!Flags.isByVal())
      continue;

    SDValue Arg = OutVals[i];
    unsigned Size = Flags.getByValSize();
    unsigned Align = Flags.getByValAlign();

    int FI = MFI->CreateStackObject(Size, Align, false);
    SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy());
    SDValue SizeNode = DAG.getConstant(Size, MVT::i32);

    Chain = DAG.getMemcpy(Chain, dl, FIPtr, Arg, SizeNode, Align,
                          false,        //isVolatile,
                          (Size <= 32), //AlwaysInline if size <= 32
                          MachinePointerInfo(), MachinePointerInfo());
    ByValArgs.push_back(FIPtr);
  }

  Chain = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(ArgsSize, true));

  SmallVector<std::pair<unsigned, SDValue>, 8> RegsToPass;
  SmallVector<SDValue, 8> MemOpChains;

  bool hasStructRetAttr = false;
  // Walk the register/memloc assignments, inserting copies/loads.
  for (unsigned i = 0, realArgIdx = 0, byvalArgIdx = 0, e = ArgLocs.size();
       i != e;
       ++i, ++realArgIdx) {
    CCValAssign &VA = ArgLocs[i];
    SDValue Arg = OutVals[realArgIdx];

    ISD::ArgFlagsTy Flags = Outs[realArgIdx].Flags;

    //Use local copy if it is a byval arg.
    if (Flags.isByVal())
      Arg = ByValArgs[byvalArgIdx++];

    // Promote the value if needed.
    switch (VA.getLocInfo()) {
    default: llvm_unreachable("Unknown loc info!");
    case CCValAssign::Full: break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, dl, VA.getLocVT(), Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, dl, VA.getLocVT(), Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, dl, VA.getLocVT(), Arg);
      break;
    case CCValAssign::BCvt:
      Arg = DAG.getNode(ISD::BITCAST, dl, VA.getLocVT(), Arg);
      break;
    }

    if (Flags.isSRet()) {
      // Structure return
      assert(VA.needsCustom());
      SDValue StackPtr = DAG.getRegister(SP::S29, MVT::i32);
      SDValue PtrOff = DAG.getIntPtrConstant(64);
      PtrOff = DAG.getNode(ISD::ADD, dl, MVT::i32, StackPtr, PtrOff);
      MemOpChains.push_back(DAG.getStore(Chain, dl, Arg, PtrOff,
                                         MachinePointerInfo(),
                                         false, false, 0));
      hasStructRetAttr = true;
      continue;
    }

    // Arguments that can be passed on register must be kept at
    // RegsToPass vector
    if (VA.isRegLoc()) {
        RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
        continue;
    }

    assert(VA.isMemLoc());

    // Create a store off the stack pointer for this argument.
    SDValue StackPtr = DAG.getRegister(SP::S29, MVT::i32);
    SDValue PtrOff = DAG.getIntPtrConstant(VA.getLocMemOffset());
    PtrOff = DAG.getNode(ISD::ADD, dl, MVT::i32, StackPtr, PtrOff);
    MemOpChains.push_back(DAG.getStore(Chain, dl, Arg, PtrOff,
                                       MachinePointerInfo(),
                                       false, false, 0));
  }

  // Emit all stores, make sure the occur before any copies into physregs.
  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other,
                        &MemOpChains[0], MemOpChains.size());

  // Build a sequence of copy-to-reg nodes chained together with token
  // chain and flag operands which copy the outgoing args into registers.
  // The InFlag in necessary since all emitted instructions must be
  // stuck together.
  SDValue InFlag;
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i) {
    Chain = DAG.getCopyToReg(Chain, dl, RegsToPass[i].first, RegsToPass[i].second, InFlag);
    InFlag = Chain.getValue(1);
  }

  unsigned SRetArgSize = (hasStructRetAttr)? getSRetArgSize(DAG, Callee):0;

  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee))
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), dl, MVT::i32);
  else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee))
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), MVT::i32);

  // Returns a chain & a flag for retval copy to use
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);
  if (hasStructRetAttr)
    Ops.push_back(DAG.getTargetConstant(SRetArgSize, MVT::i32));
  for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i)
    Ops.push_back(DAG.getRegister(RegsToPass[i].first,
                                  RegsToPass[i].second.getValueType()));

  // Add a register mask operand representing the call-preserved registers.
  const TargetRegisterInfo *TRI = getTargetMachine().getRegisterInfo();
  const uint32_t *Mask = TRI->getCallPreservedMask(CLI.CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(CLI.DAG.getRegisterMask(Mask));

  if (InFlag.getNode())
    Ops.push_back(InFlag);

  Chain = DAG.getNode(SPISD::CALL, dl, NodeTys, &Ops[0], Ops.size());
  InFlag = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(ArgsSize, true),
                             DAG.getIntPtrConstant(0, true), InFlag);
  InFlag = Chain.getValue(1);

  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState RVInfo(CallConv, isVarArg, DAG.getMachineFunction(),
                 DAG.getTarget(), RVLocs, *DAG.getContext());

  RVInfo.AnalyzeCallResult(Ins, RetCC_VectorProc32);

  // Copy all of the result registers out of their specified physreg.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLocs[i].getLocReg(),
                               RVLocs[i].getValVT(), InFlag).getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

unsigned
VectorProcTargetLowering::getSRetArgSize(SelectionDAG &DAG, SDValue Callee) const
{
  const Function *CalleeFn = 0;
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    CalleeFn = dyn_cast<Function>(G->getGlobal());
  } else if (ExternalSymbolSDNode *E =
             dyn_cast<ExternalSymbolSDNode>(Callee)) {
    const Function *Fn = DAG.getMachineFunction().getFunction();
    const Module *M = Fn->getParent();
    CalleeFn = M->getFunction(E->getSymbol());
  }

  if (!CalleeFn)
    return 0;

  assert(CalleeFn->hasStructRetAttr() &&
         "Callee does not have the StructRet attribute.");

  PointerType *Ty = cast<PointerType>(CalleeFn->arg_begin()->getType());
  Type *ElementTy = Ty->getElementType();
  return getDataLayout()->getTypeAllocSize(ElementTy);
}

VectorProcTargetLowering::VectorProcTargetLowering(TargetMachine &TM)
  : TargetLowering(TM, new TargetLoweringObjectFileELF()) {

  Subtarget = &TM.getSubtarget<VectorProcSubtarget>();

  // Set up the register classes.
  addRegisterClass(MVT::i32, &SP::ScalarRegRegClass);
  addRegisterClass(MVT::f32, &SP::ScalarRegRegClass);
  addRegisterClass(MVT::v16i1, &SP::ScalarRegRegClass);
  addRegisterClass(MVT::v16i32, &SP::VectorRegRegClass);
  addRegisterClass(MVT::v16f32, &SP::VectorRegRegClass);

  setOperationAction(ISD::BR_CC, MVT::i32, Expand);
  setOperationAction(ISD::BR_CC, MVT::f32, Expand);
  setOperationAction(ISD::BRCOND, MVT::i32, Expand);
  setOperationAction(ISD::BRCOND, MVT::f32, Expand);
  setOperationAction(ISD::BUILD_VECTOR, MVT::v16f32, Custom);
  setOperationAction(ISD::BUILD_VECTOR, MVT::v16i32, Custom);
  setOperationAction(ISD::INSERT_VECTOR_ELT, MVT::v16f32, Custom);
  setOperationAction(ISD::INSERT_VECTOR_ELT, MVT::v16i32, Custom);
  setOperationAction(ISD::VECTOR_SHUFFLE, MVT::v16i32, Custom);
  setOperationAction(ISD::VECTOR_SHUFFLE, MVT::v16f32, Custom);
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);
  setOperationAction(ISD::GlobalAddress, MVT::f32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::f32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::v16i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::v16f32, Custom);

  setStackPointerRegisterToSaveRestore(SP::S29);

  setMinFunctionAlignment(2);

  computeRegisterProperties();
}

const char *VectorProcTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch (Opcode) {
  default: return 0;
  case SPISD::CALL:       return "SPISD::CALL";
  case SPISD::RET_FLAG:   return "SPISD::RET_FLAG";
  case SPISD::LOAD_LITERAL: return "SPISD::LOAD_LITERAL";
  case SPISD::SPLAT: return "SPISD::SPLAT";
  case SPISD::SEL_COND_RESULT: return "SPISD::SEL_COND_RESULT";
  }
}

void VectorProcTargetLowering::computeMaskedBitsForTargetNode(const SDValue Op,
                                                         APInt &KnownZero,
                                                         APInt &KnownOne,
                                                         const SelectionDAG &DAG,
                                                         unsigned Depth) const 
{
}

SDValue VectorProcTargetLowering::
LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const
{
	EVT PtrVT = getPointerTy();
	DebugLoc dl = Op.getDebugLoc();
	const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
	SDValue GA = DAG.getTargetGlobalAddress(GV, dl, MVT::i32);
	return DAG.getNode(SPISD::LOAD_LITERAL, dl, MVT::i32, GA);
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

SDValue
VectorProcTargetLowering::LowerBUILD_VECTOR(SDValue Op, SelectionDAG &DAG) const {
	MVT VT = Op.getValueType().getSimpleVT();
	DebugLoc dl = Op.getDebugLoc();

	if (isSplatVector(Op.getNode()))
	{
		// This is a constant node that is duplicated to all lanes.
		// Convert it to a SPLAT node.
		return DAG.getNode(SPISD::SPLAT, dl, VT, Op.getOperand(0));
	}
	
	return SDValue();
}

SDValue
VectorProcTargetLowering::LowerVECTOR_SHUFFLE(SDValue Op, SelectionDAG &DAG) const {
	MVT VT = Op.getValueType().getSimpleVT();
	DebugLoc dl = Op.getDebugLoc();

	//
	// The way to turn a scalar value into a splat in LLVM is 
	// with the following pattern:
	// %single = insertelement <16 x i32> undef, i32 %b, i32 0 
	// %vector = shufflevector <16 x i32> %single, <16 x i32> undef, 
    //                       <16 x i32> zeroinitializer
	// Detect this pattern and convert it to a SPLAT node.
	//
	if (ISD::isBuildVectorAllZeros(Op.getOperand(1).getNode())
		&& Op.getOperand(0).getOpcode() == ISD::INSERT_VECTOR_ELT
		&& isZero(Op.getOperand(0).getOperand(2)))
	{
		return DAG.getNode(SPISD::SPLAT, dl, VT, Op.getOperand(0).getOperand(1));
	}

	// Otherwise, just let normal instruction selection take care of this.
	// (there is a rule for actual shuffles)
	return SDValue();
}

// (VECTOR, VAL, IDX)
// Convert to a vselect with a mask (1 << IDX) and a splatted scalar operand.
SDValue
VectorProcTargetLowering::LowerINSERT_VECTOR_ELT(SDValue Op, SelectionDAG &DAG) const {
	MVT VT = Op.getValueType().getSimpleVT();
	DebugLoc dl = Op.getDebugLoc();

	SDValue mask = DAG.getNode(ISD::SHL, dl, MVT::i32, DAG.getConstant(1, MVT::i32),
		Op.getOperand(1));
	SDValue splat = DAG.getNode(SPISD::SPLAT, dl, VT, Op.getOperand(2));
	return DAG.getNode(ISD::VSELECT, dl, VT, mask, splat, Op.getOperand(0));
}

SDValue
VectorProcTargetLowering::LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const {
  DebugLoc DL = Op.getDebugLoc();
  EVT Ty = Op.getOperand(0).getValueType();
  SDValue Pred = DAG.getNode(ISD::SETCC, DL, getSetCCResultType(Ty),
                             Op.getOperand(0), Op.getOperand(1),
                             Op.getOperand(4));

  return DAG.getNode(SPISD::SEL_COND_RESULT, DL, Op.getValueType(), Pred, 
  	Op.getOperand(2), Op.getOperand(3));
}

SDValue VectorProcTargetLowering::
LowerOperation(SDValue Op, SelectionDAG &DAG) const {
	switch (Op.getOpcode())
	{
		case ISD::VECTOR_SHUFFLE: return LowerVECTOR_SHUFFLE(Op, DAG);
        case ISD::BUILD_VECTOR:  return LowerBUILD_VECTOR(Op, DAG);
		case ISD::GlobalAddress: return LowerGlobalAddress(Op, DAG);
		case ISD::INSERT_VECTOR_ELT: return LowerINSERT_VECTOR_ELT(Op, DAG);	
		case ISD::SELECT_CC: return LowerSELECT_CC(Op, DAG);
		default:
			llvm_unreachable("Should not custom lower this!");
	}
}

EVT VectorProcTargetLowering::getSetCCResultType(EVT VT) const {
  if (!VT.isVector())
    return MVT::i32;

  return VT.changeVectorElementTypeToInteger();
}

MachineBasicBlock *
VectorProcTargetLowering::EmitInstrWithCustomInserter(MachineInstr *MI,
                                                 MachineBasicBlock *BB) const {

  const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
  DebugLoc DL = MI->getDebugLoc();

  // The instruction we are replacing is SELECTI (dest, predicate, trueval, falseval)

  // To "insert" a SELECT_CC instruction, we actually have to insert the
  // diamond control-flow pattern.  The incoming instruction knows the
  // destination vreg to set, the condition code register to branch on, the
  // true/false values to select between, and a branch opcode to use.
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator It = BB;
  ++It;

  //  thisMBB:
  //  ...
  //   TrueVal = ...
  //   setcc r1, r2, r3
  //   if r1 goto copy1MBB
  //   fallthrough --> copy0MBB
  MachineBasicBlock *thisMBB  = BB;
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *copy0MBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *sinkMBB  = F->CreateMachineBasicBlock(LLVM_BB);
  F->insert(It, copy0MBB);
  F->insert(It, sinkMBB);

  // Transfer the remainder of BB and its successor edges to sinkMBB.
  sinkMBB->splice(sinkMBB->begin(), BB,
                  llvm::next(MachineBasicBlock::iterator(MI)),
                  BB->end());
  sinkMBB->transferSuccessorsAndUpdatePHIs(BB);

  // Next, add the true and fallthrough blocks as its successors.
  BB->addSuccessor(copy0MBB);
  BB->addSuccessor(sinkMBB);

  BuildMI(BB, DL, TII->get(SP::IFTRUE)).addReg(MI->getOperand(1).getReg())
    .addMBB(sinkMBB);

  //  copy0MBB:
  //   %FalseValue = ...
  //   # fallthrough to sinkMBB
  BB = copy0MBB;

  // Update machine-CFG edges
  BB->addSuccessor(sinkMBB);

  //  sinkMBB:
  //   %Result = phi [ %TrueValue, thisMBB ], [ %FalseValue, copy0MBB ]
  //  ...
  BB = sinkMBB;

  BuildMI(*BB, BB->begin(), DL,
          TII->get(SP::PHI), MI->getOperand(0).getReg())
    .addReg(MI->getOperand(2).getReg()).addMBB(thisMBB)
    .addReg(MI->getOperand(3).getReg()).addMBB(copy0MBB);

  MI->eraseFromParent();   // The pseudo instruction is gone now.
  return BB;
}


//===----------------------------------------------------------------------===//
//                         VectorProc Inline Assembly Support
//===----------------------------------------------------------------------===//

/// getConstraintType - Given a constraint letter, return the type of
/// constraint it is for this target.
VectorProcTargetLowering::ConstraintType
VectorProcTargetLowering::getConstraintType(const std::string &Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    default:  break;
    case 'r': return C_RegisterClass;
    }
  }

  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass*>
VectorProcTargetLowering::getRegForInlineAsmConstraint(const std::string &Constraint,
                                                  EVT VT) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    case 'r':
      return std::make_pair(0U, &SP::ScalarRegRegClass);
    }
  }

  return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

bool
VectorProcTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const {
  // The VectorProc target isn't yet aware of offsets.
  return false;
}
