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

#include "VectorProcGenCallingConv.inc"

SDValue
VectorProcTargetLowering::LowerReturn(SDValue Chain,
                                 CallingConv::ID CallConv, bool IsVarArg,
                                 const SmallVectorImpl<ISD::OutputArg> &Outs,
                                 const SmallVectorImpl<SDValue> &OutVals,
                                 SDLoc dl, SelectionDAG &DAG) const 
{
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

	// Copy the result values into the output registers.
	for (unsigned i = 0; i != RVLocs.size(); ++i) {
		CCValAssign &VA = RVLocs[i];
		assert(VA.isRegLoc() && "Can only return in registers!");
		Chain = DAG.getCopyToReg(Chain, dl, VA.getLocReg(), OutVals[i], Flag);

		// Guarantee that all emitted copies are stuck together with flags.
		Flag = Chain.getValue(1);
		RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
	}

	if (MF.getFunction()->hasStructRetAttr()) {
		VectorProcMachineFunctionInfo *SFI = MF.getInfo<VectorProcMachineFunctionInfo>();
		unsigned Reg = SFI->getSRetReturnReg();
		if (!Reg)
			llvm_unreachable("sret virtual register not created in the entry block");

		SDValue Val = DAG.getCopyFromReg(Chain, dl, Reg, getPointerTy());
		Chain = DAG.getCopyToReg(Chain, dl, VectorProc::S0, Val, Flag);
		Flag = Chain.getValue(1);
		RetOps.push_back(DAG.getRegister(VectorProc::S0, getPointerTy()));
	}

	RetOps[0] = Chain;  // Update chain.

	// Add the flag if we have it.
	if (Flag.getNode())
		RetOps.push_back(Flag);

	return DAG.getNode(VectorProcISD::RET_FLAG, dl, MVT::Other, &RetOps[0], RetOps.size());
}

SDValue VectorProcTargetLowering::
LowerFormalArguments(SDValue Chain,
                        CallingConv::ID CallConv,
                        bool isVarArg,
                        const SmallVectorImpl<ISD::InputArg> &Ins,
                        SDLoc dl,
                        SelectionDAG &DAG,
                        SmallVectorImpl<SDValue> &InVals) const 
{
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
	for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
		CCValAssign &VA = ArgLocs[i];

		if (i == 0  && Ins[i].Flags.isSRet()) {
			// Structure return?
			int FrameIdx = MF.getFrameInfo()->CreateFixedObject(4, 64, true);
			SDValue FIPtr = DAG.getFrameIndex(FrameIdx, MVT::i32);
			SDValue Arg = DAG.getLoad(MVT::i32, dl, Chain, FIPtr,
				MachinePointerInfo(), false, false, false, 0);
			InVals.push_back(Arg);
			continue;
		}

		if (VA.isRegLoc()) {
			// Argument is in register
			EVT RegVT = VA.getLocVT();
			const TargetRegisterClass *RC;

			if (RegVT == MVT::i32 || RegVT == MVT::f32 || RegVT == MVT::v16i1)
				RC = &VectorProc::ScalarRegRegClass;
			else if (RegVT == MVT::v16i32 || RegVT == MVT::v16f32)
				RC = &VectorProc::VectorRegRegClass;
			else
				llvm_unreachable("Unsupported formal argument type");

			unsigned VReg = RegInfo.createVirtualRegister(RC);
			MF.getRegInfo().addLiveIn(VA.getLocReg(), VReg);
			SDValue Arg = DAG.getCopyFromReg(Chain, dl, VReg, VA.getLocVT());
			InVals.push_back(Arg);
			continue;
		}

		// Otherwise this parameter is on the stack
		assert(VA.isMemLoc());

		int FI = MF.getFrameInfo()->CreateFixedObject(VA.getValVT().getSizeInBits() / 8,
			VA.getLocMemOffset(), true);
		SDValue FIPtr = DAG.getFrameIndex(FI, getPointerTy());
		SDValue Load;
		if (VA.getValVT() == MVT::i32 || VA.getValVT() == MVT::f32
			|| VA.getValVT() == MVT::v16i32) {
			// Primitive types are loaded directly from the stack
			Load = DAG.getLoad(VA.getValVT(), dl, Chain, FIPtr,
				MachinePointerInfo(), false, false, false, 0);
		} else {
			// This is a smaller type (char, etc).  Sign extend.
			ISD::LoadExtType LoadOp = ISD::SEXTLOAD;
			unsigned Offset = 4 - std::max(1U, VA.getValVT().getSizeInBits() / 8);
			FIPtr = DAG.getNode(ISD::ADD, dl, MVT::i32, FIPtr,
			DAG.getConstant(Offset, MVT::i32));
			Load = DAG.getExtLoad(LoadOp, dl, MVT::i32, Chain, FIPtr,
				MachinePointerInfo(), VA.getValVT(), false, false,0);
			Load = DAG.getNode(ISD::TRUNCATE, dl, VA.getValVT(), Load);
		}
		
		InVals.push_back(Load);
	}

	if (MF.getFunction()->hasStructRetAttr()) {
		// When a function returns a structure, the address of the return value
		// is placed in the first physical register.
		VectorProcMachineFunctionInfo *SFI = MF.getInfo<VectorProcMachineFunctionInfo>();
		unsigned Reg = SFI->getSRetReturnReg();
		if (!Reg) {
			Reg = MF.getRegInfo().createVirtualRegister(&VectorProc::ScalarRegRegClass);
			SFI->setSRetReturnReg(Reg);
		}

		SDValue Copy = DAG.getCopyToReg(DAG.getEntryNode(), dl, Reg, InVals[0]);
		Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other, Copy, Chain);
	}

	// Here is where variable arguments would be handled.
	if (isVarArg) {
		llvm_unreachable("variable arguments not implemented yet");
	}

	return Chain;
}

// Generate code to call a function
SDValue
VectorProcTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
	SmallVectorImpl<SDValue> &InVals) const 
{
	SelectionDAG &DAG = CLI.DAG;
	SDLoc &dl = CLI.DL;
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

	MachineFrameInfo *MFI = DAG.getMachineFunction().getFrameInfo();

	// Analyze operands of the call, assigning locations to each operand.
	// VectorProcCallingConv.td will auto-generate CC_VectorProc32, which 
	// knows how to handle operands (what go in registers vs. stack, etc).
	SmallVector<CCValAssign, 16> ArgLocs;
	CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(),
		DAG.getTarget(), ArgLocs, *DAG.getContext());
	CCInfo.AnalyzeCallOperands(Outs, CC_VectorProc32);

	// Get the size of the outgoing arguments stack space requirement.
	unsigned ArgsSize = CCInfo.getNextStackOffset();

	// We always keep the stack pointer 64 byte aligned so we can use block
	// loads/stores for vector arguments
	ArgsSize = (ArgsSize + 63) & ~63;

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
		Chain = DAG.getMemcpy(Chain, dl, FIPtr, Arg, SizeNode, Align,
			false,        //isVolatile,
			(Size <= 32), //AlwaysInline if size <= 32
			MachinePointerInfo(), MachinePointerInfo());

		ByValArgs.push_back(FIPtr);
	}

	// CALLSEQ_START will decrement the stack to reserve space
	Chain = DAG.getCALLSEQ_START(Chain, DAG.getIntPtrConstant(ArgsSize, true), dl);

	SmallVector<std::pair<unsigned, SDValue>, 8> RegsToPass;
	SmallVector<SDValue, 8> MemOpChains;

	// Walk through arguments, storing each one to the proper palce
	bool hasStructRetAttr = false;
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

			default: 
				llvm_unreachable("Unknown loc info!");
		}

		if (Flags.isSRet()) {
			// Structure return
			assert(VA.needsCustom());
			SDValue StackPtr = DAG.getRegister(VectorProc::SP_REG, MVT::i32);
			SDValue PtrOff = DAG.getIntPtrConstant(64);
			PtrOff = DAG.getNode(ISD::ADD, dl, MVT::i32, StackPtr, PtrOff);
			MemOpChains.push_back(DAG.getStore(Chain, dl, Arg, PtrOff,
				MachinePointerInfo(), false, false, 0));
			hasStructRetAttr = true;
			continue;
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
		PtrOff = DAG.getNode(ISD::ADD, dl, MVT::i32, StackPtr, PtrOff);
		MemOpChains.push_back(DAG.getStore(Chain, dl, Arg, PtrOff,
			MachinePointerInfo(), false, false, 0));
	}

	// Emit all stores, make sure the occur before any copies into physregs.
	if (!MemOpChains.empty())
	{
		Chain = DAG.getNode(ISD::TokenFactor, dl, MVT::Other,
			&MemOpChains[0], MemOpChains.size());
	}

	// Build a sequence of copy-to-reg nodes chained together with token
	// chain and flag operands which copy the outgoing args into registers.
	// The InFlag in necessary since all emitted instructions must be
	// stuck together.
	SDValue InFlag;
	for (unsigned i = 0, e = RegsToPass.size(); i != e; ++i) {
		Chain = DAG.getCopyToReg(Chain, dl, RegsToPass[i].first, RegsToPass[i].second, InFlag);
		InFlag = Chain.getValue(1);
	}

	unsigned SRetArgSize = hasStructRetAttr ? getSRetArgSize(DAG, Callee) : 0;

	// Get the function address.
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
	{
		Ops.push_back(DAG.getRegister(RegsToPass[i].first,
			RegsToPass[i].second.getValueType()));
	}
	
	// Add a register mask operand representing the call-preserved registers.
	const TargetRegisterInfo *TRI = getTargetMachine().getRegisterInfo();
	const uint32_t *Mask = TRI->getCallPreservedMask(CLI.CallConv);
	assert(Mask && "Missing call preserved mask for calling convention");
	Ops.push_back(CLI.DAG.getRegisterMask(Mask));

	if (InFlag.getNode())
		Ops.push_back(InFlag);

	Chain = DAG.getNode(VectorProcISD::CALL, dl, NodeTys, &Ops[0], Ops.size());
	InFlag = Chain.getValue(1);

	Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(ArgsSize, true),
		DAG.getIntPtrConstant(0, true), InFlag, dl);
	InFlag = Chain.getValue(1);

	// The call has returned, handle return values
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
	} else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee)) {
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
	: TargetLowering(TM, new TargetLoweringObjectFileELF()) 
{
	Subtarget = &TM.getSubtarget<VectorProcSubtarget>();

	// Set up the register classes.
	addRegisterClass(MVT::i32, &VectorProc::ScalarRegRegClass);
	addRegisterClass(MVT::f32, &VectorProc::ScalarRegRegClass);
	addRegisterClass(MVT::v16i1, &VectorProc::ScalarRegRegClass);
	addRegisterClass(MVT::v16i32, &VectorProc::VectorRegRegClass);
	addRegisterClass(MVT::v16f32, &VectorProc::VectorRegRegClass);

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
	setOperationAction(ISD::ConstantPool, MVT::i32, Custom);
	setOperationAction(ISD::ConstantPool, MVT::f32, Custom);
	setOperationAction(ISD::Constant, MVT::i32, Custom);
	setOperationAction(ISD::FDIV, MVT::f32, Custom);
	setOperationAction(ISD::FDIV, MVT::v16f32, Custom);

	setStackPointerRegisterToSaveRestore(VectorProc::SP_REG);
	setMinFunctionAlignment(2);
	computeRegisterProperties();
}

const char *VectorProcTargetLowering::getTargetNodeName(unsigned Opcode) const {
	switch (Opcode) {
		case VectorProcISD::CALL:       return "VectorProcISD::CALL";
		case VectorProcISD::RET_FLAG:   return "VectorProcISD::RET_FLAG";
		case VectorProcISD::LOAD_LITERAL: return "VectorProcISD::LOAD_LITERAL";
		case VectorProcISD::SPLAT: return "VectorProcISD::SPLAT";
		case VectorProcISD::SEL_COND_RESULT: return "VectorProcISD::SEL_COND_RESULT";
		default: return 0;
	}
}

// Global addresses are stored in the per-function constant pool.
SDValue 
VectorProcTargetLowering::LowerGlobalAddress(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	const GlobalValue *GV = cast<GlobalAddressSDNode>(Op)->getGlobal();
	SDValue CPIdx = DAG.getTargetConstantPool(GV, MVT::i32);
	return DAG.getLoad(MVT::i32, dl, DAG.getEntryNode(), CPIdx,
		MachinePointerInfo::getConstantPool(), false, false, false, 4);
}

/// isSplatVector - Returns true if N is a BUILD_VECTOR node whose elements are
/// all the same.
static bool isSplatVector(SDNode *N) 
{
	SDValue SplatValue = N->getOperand(0);
	for (unsigned i = 1, e = N->getNumOperands(); i != e; ++i)
		if (N->getOperand(i) != SplatValue)
			return false;

	return true;
}

static bool isZero(SDValue V) 
{
  ConstantSDNode *C = dyn_cast<ConstantSDNode>(V);
  return C && C->isNullValue();
}

SDValue
VectorProcTargetLowering::LowerBUILD_VECTOR(SDValue Op, SelectionDAG &DAG) const 
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);

	if (isSplatVector(Op.getNode()))
	{
		// This is a constant node that is duplicated to all lanes.
		// Convert it to a SPLAT node.
		return DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(0));
	}
	
	return SDValue();
}

SDValue
VectorProcTargetLowering::LowerVECTOR_SHUFFLE(SDValue Op, SelectionDAG &DAG) const 
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);

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
		return DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(0).getOperand(1));
	}

	// Otherwise, just let normal instruction selection take care of this.
	// (there is a rule for actual shuffles)
	return SDValue();
}

// (VECTOR, VAL, IDX)
// Convert to a vselect with a mask (1 << IDX) and a splatted scalar operand.
SDValue
VectorProcTargetLowering::LowerINSERT_VECTOR_ELT(SDValue Op, SelectionDAG &DAG) const 
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);

	SDValue mask = DAG.getNode(ISD::SHL, dl, MVT::i32, DAG.getConstant(1, MVT::i32),
		Op.getOperand(2));
	SDValue splat = DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(1));
	return DAG.getNode(ISD::VSELECT, dl, VT, mask, splat, Op.getOperand(0));
}

// This architecture does not support conditional moves for scalar registers.
// We must convert this into a set of conditional branches.  We do this by
// creating a pseudo-instruction SEL_COND_RESULT, which will later be transformed.
SDValue
VectorProcTargetLowering::LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const 
{
	SDLoc dl(Op);
	EVT Ty = Op.getOperand(0).getValueType();
	SDValue Pred = DAG.getNode(ISD::SETCC, dl, getSetCCResultType(*DAG.getContext(), Ty),
		Op.getOperand(0), Op.getOperand(1),
		Op.getOperand(4));

	return DAG.getNode(VectorProcISD::SEL_COND_RESULT, dl, Op.getValueType(), Pred, 
		Op.getOperand(2), Op.getOperand(3));
}

SDValue 
VectorProcTargetLowering::LowerConstantPool(SDValue Op, SelectionDAG &DAG) const 
{
	SDLoc dl(Op);
	EVT PtrVT = Op.getValueType();
	ConstantPoolSDNode *CP = cast<ConstantPoolSDNode>(Op);
	SDValue Res;
	if (CP->isMachineConstantPoolEntry())
	{
		Res = DAG.getTargetConstantPool(CP->getMachineCPVal(), PtrVT,
			CP->getAlignment());
	}
	else
	{
		Res = DAG.getTargetConstantPool(CP->getConstVal(), PtrVT,
			CP->getAlignment());
	}
	
	return Res;
}

SDValue 
VectorProcTargetLowering::LowerConstant(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	ConstantSDNode *C = cast<ConstantSDNode>(Op);
	if (C->getAPIntValue().abs().ult(0x4000))
	{
		// Don't need to convert to constant pool reference.  This will fit in
		// the immediate field of a single instruction, sign extended (15 bits).
		return SDValue();	
	}
		
	SDValue CPIdx = DAG.getConstantPool(C->getConstantIntValue(), MVT::i32);
	return DAG.getLoad(MVT::i32, dl, DAG.getEntryNode(), CPIdx,
		MachinePointerInfo::getConstantPool(), false, false, false, 4);
}

// There is no native floating point division, but we can convert this to a 
// reciprocal/multiply operation.  If the first parameter is constant 1.0, then 
// just a reciprocal will suffice.
SDValue 
VectorProcTargetLowering::LowerFDIV(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	
	EVT type = Op.getOperand(1).getValueType();

	SDValue two = DAG.getConstantFP(2.0, type);
	SDValue denom = Op.getOperand(1);
	SDValue estimate = DAG.getNode(VectorProcISD::RECIPROCAL_EST, dl, type, denom);
	
	// Perform a series of newton/raphson refinements.  Each iteration doubles
	// the precision. The initial estimate has 6 bits of precision, so two iteration
	// results in 24 bits, which is larger than the significand.
	for (int i = 0; i < 2; i++)
	{
		// trial = x * estimate (ideally, x * 1/x should be 1.0)
		// error = 2.0 - trial
		// estimate = estimate * error
		SDValue trial = DAG.getNode(ISD::FMUL, dl, type, estimate, denom);
		SDValue error = DAG.getNode(ISD::FSUB, dl, type, two, trial);
		estimate = DAG.getNode(ISD::FMUL, dl, type, estimate, error);
	}

	// Check if the first parameter is constant 1.0.  If so, we don't need
	// to multiply.
	bool isOne = false;
	if (type.isVector())
	{
		if (isSplatVector(Op.getOperand(0).getNode()))
		{
			ConstantFPSDNode *C = dyn_cast<ConstantFPSDNode>(Op.getOperand(0).getOperand(0));
			isOne = C && C->isExactlyValue(1.0);
		}
	}
	else
	{
		ConstantFPSDNode *C = dyn_cast<ConstantFPSDNode>(Op.getOperand(0));
		isOne = C && C->isExactlyValue(1.0);
	}

	if (!isOne)
		estimate = DAG.getNode(ISD::FMUL, dl, type, Op.getOperand(0), estimate);

	return estimate;
}

SDValue VectorProcTargetLowering::
LowerOperation(SDValue Op, SelectionDAG &DAG) const 
{
	switch (Op.getOpcode())
	{
		case ISD::VECTOR_SHUFFLE: return LowerVECTOR_SHUFFLE(Op, DAG);
		case ISD::BUILD_VECTOR:  return LowerBUILD_VECTOR(Op, DAG);
		case ISD::GlobalAddress: return LowerGlobalAddress(Op, DAG);
		case ISD::INSERT_VECTOR_ELT: return LowerINSERT_VECTOR_ELT(Op, DAG);	
		case ISD::SELECT_CC: return LowerSELECT_CC(Op, DAG);
		case ISD::ConstantPool: return LowerConstantPool(Op, DAG);
		case ISD::Constant: return LowerConstant(Op, DAG);
		case ISD::FDIV: return LowerFDIV(Op, DAG);
		default:
			llvm_unreachable("Should not custom lower this!");
	}
}

EVT VectorProcTargetLowering::getSetCCResultType(LLVMContext &Context, EVT VT) const 
{
	if (!VT.isVector())
		return MVT::i32;

	return VT.changeVectorElementTypeToInteger();
}

MachineBasicBlock *
VectorProcTargetLowering::EmitInstrWithCustomInserter(MachineInstr *MI,
	MachineBasicBlock *BB) const 
{
	const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();
	DebugLoc dl = MI->getDebugLoc();

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

	BuildMI(BB, dl, TII->get(VectorProc::IFTRUE)).addReg(MI->getOperand(1).getReg())
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

	BuildMI(*BB, BB->begin(), dl, TII->get(VectorProc::PHI), MI->getOperand(0).getReg())
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
			case 'r': return C_RegisterClass;
			default:  break;
		}
	}

	return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass*>
VectorProcTargetLowering::getRegForInlineAsmConstraint(const std::string &Constraint,
	MVT VT) const 
{
	if (Constraint.size() == 1) {
		switch (Constraint[0]) {
			case 'r':
				return std::make_pair(0U, &VectorProc::ScalarRegRegClass);
		}
	}

	return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

bool
VectorProcTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const {
  // The VectorProc target isn't yet aware of offsets.
  return false;
}
