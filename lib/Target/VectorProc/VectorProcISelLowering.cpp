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

		if (VA.isRegLoc()) {
			// Argument is in register
			EVT RegVT = VA.getLocVT();
			const TargetRegisterClass *RC;

			if (RegVT == MVT::i32 || RegVT == MVT::f32)
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
VectorProcTargetLowering::getJumpTableEncoding() const 
{
	return MachineJumpTableInfo::EK_Inline;
}

VectorProcTargetLowering::VectorProcTargetLowering(TargetMachine &TM)
	: TargetLowering(TM, new VectorProcTargetObjectFile()) 
{
	Subtarget = &TM.getSubtarget<VectorProcSubtarget>();

	// Set up the register classes.
	addRegisterClass(MVT::i32, &VectorProc::ScalarRegRegClass);
	addRegisterClass(MVT::f32, &VectorProc::ScalarRegRegClass);
	addRegisterClass(MVT::v16i32, &VectorProc::VectorRegRegClass);
	addRegisterClass(MVT::v16f32, &VectorProc::VectorRegRegClass);

	setOperationAction(ISD::BR_CC, MVT::i32, Expand);
	setOperationAction(ISD::BR_CC, MVT::f32, Expand);
	setOperationAction(ISD::BRCOND, MVT::i32, Expand);
	setOperationAction(ISD::BRCOND, MVT::f32, Expand);
	setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
	setOperationAction(ISD::CTPOP, MVT::i32, Expand);
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
	setOperationAction(ISD::SELECT, MVT::i32, Expand);
	setOperationAction(ISD::ConstantPool, MVT::i32, Custom);
	setOperationAction(ISD::ConstantPool, MVT::f32, Custom);
	setOperationAction(ISD::Constant, MVT::i32, Custom);
	setOperationAction(ISD::FDIV, MVT::f32, Custom);
	setOperationAction(ISD::FDIV, MVT::v16f32, Custom);
	setOperationAction(ISD::BR_JT, MVT::Other, Custom);
	setOperationAction(ISD::SCALAR_TO_VECTOR, MVT::v16i32, Custom);
	setOperationAction(ISD::SCALAR_TO_VECTOR, MVT::v16f32, Custom);
	setOperationAction(ISD::ROTL, MVT::i32, Expand);
	setOperationAction(ISD::ROTR, MVT::i32, Expand);
	setOperationAction(ISD::FNEG, MVT::f32, Custom);
	setOperationAction(ISD::FNEG, MVT::v16f32, Custom);
	setOperationAction(ISD::SETCC, MVT::f32, Custom);
	setOperationAction(ISD::SETCC, MVT::v16f32, Custom);
	setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i32, Custom);
	setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i32, Custom);
	setOperationAction(ISD::UDIVREM, MVT::i32, Expand);
	setOperationAction(ISD::SDIVREM, MVT::i32, Expand);
	setOperationAction(ISD::MULHU, MVT::i32, Expand);
	setOperationAction(ISD::MULHS, MVT::i32, Expand);
	setOperationAction(ISD::UMUL_LOHI, MVT::i32, Expand);
	setOperationAction(ISD::SMUL_LOHI, MVT::i32, Expand);
	setOperationAction(ISD::FP_TO_UINT, MVT::i32, Expand);
	setOperationAction(ISD::UINT_TO_FP, MVT::i32, Custom);

	// Hardware does not have an integer divider, so convert these to 
	// library calls
    setOperationAction(ISD::UDIV,  MVT::i32, Expand);	// __udivsi3
    setOperationAction(ISD::UREM,  MVT::i32, Expand);	// __umodsi3
    setOperationAction(ISD::SDIV,  MVT::i32, Expand);	// __divsi3
    setOperationAction(ISD::SREM,  MVT::i32, Expand);	// __modsi3

	setStackPointerRegisterToSaveRestore(VectorProc::SP_REG);
	setMinFunctionAlignment(2);
	setSelectIsExpensive();		// Because there is no CMOV 
	setIntDivIsCheap(false);
	setSchedulingPreference(Sched::RegPressure);	// because we hide latency
	
	computeRegisterProperties();
}

const char *VectorProcTargetLowering::getTargetNodeName(unsigned Opcode) const {
	switch (Opcode) {
		case VectorProcISD::CALL:       return "VectorProcISD::CALL";
		case VectorProcISD::RET_FLAG:   return "VectorProcISD::RET_FLAG";
		case VectorProcISD::SPLAT: return "VectorProcISD::SPLAT";
		case VectorProcISD::SEL_COND_RESULT: return "VectorProcISD::SEL_COND_RESULT";
		case VectorProcISD::RECIPROCAL_EST: return "VectorProcISD::RECIPROCAL_EST";
		case VectorProcISD::BR_JT: return "VectorProcISD::BR_JT";
		case VectorProcISD::JT_WRAPPER: return "VectorProcISD::JT_WRAPPER";
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
	
	return SDValue();	// Expand
}

bool 
VectorProcTargetLowering::isShuffleMaskLegal(const SmallVectorImpl<int> &M, EVT VT) const
{
	if (M.size() != 16)
		return false;
	
	for (int i = 0; i < 16; i++)
	{
		if (M[i] != 0)
			return false;
	}
	
	return true;
}

//
// Look for patterns that built splats
//
SDValue
VectorProcTargetLowering::LowerVECTOR_SHUFFLE(SDValue Op, SelectionDAG &DAG) const 
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);

	// isShuffleMaskLegal should prevent this from being called inappropriately.
	assert(ISD::isBuildVectorAllZeros(Op.getOperand(2).getNode()) && "non-zero build vector");

	// Using shufflevector to build a splat like this:
	// %vector = shufflevector <16 x i32> %single, <16 x i32> (don't care), 
    //                       <16 x i32> zeroinitializer
	
	// %single = insertelement <16 x i32> (don't care), i32 %value, i32 0 
	if (Op.getOperand(0).getOpcode() == ISD::INSERT_VECTOR_ELT
		&& isZero(Op.getOperand(0).getOperand(2)))
	{
		return DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(0).getOperand(1));
	}

	// %single = scalar_to_vector i32 %b
	if (Op.getOperand(0).getOpcode() == ISD::SCALAR_TO_VECTOR)
		return DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(0).getOperand(0));

	return SDValue();
}

// (VECTOR, VAL, IDX)
// Convert to a move with a mask (0x8000 >> IDX) and a splatted scalar operand.
SDValue
VectorProcTargetLowering::LowerINSERT_VECTOR_ELT(SDValue Op, SelectionDAG &DAG) const 
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);

	// This could also be (1 << (15 - index)), which avoids the load of 0x8000
	// but requires more operations.
	SDValue mask = DAG.getNode(ISD::SRL, dl, MVT::i32, DAG.getConstant(0x8000, 
		MVT::i32), Op.getOperand(2));
	SDValue splat = DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(1));
	return DAG.getNode(ISD::INTRINSIC_WO_CHAIN, dl, VT, DAG.getConstant(Intrinsic::vp_blendi, MVT::i32),
		mask, splat, Op.getOperand(0));
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

	// The size of the immediate field is determined by the instruction format and
	// whether a mask is present.  At this level of the tree, we cannot know that,
	// so we use the smallest size.
	const int kMaxImmediateSize = 13;

	if (C->getAPIntValue().abs().ult((1 << (kMaxImmediateSize - 1)) - 1))
	{
		// Don't need to convert to constant pool reference.  This will fit in
		// the immediate field of a single instruction, sign extended.
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

// Branch using jump table
SDValue VectorProcTargetLowering::
LowerBR_JT(SDValue Op, SelectionDAG &DAG) const
{
	SDValue Chain = Op.getOperand(0);
	SDValue Table = Op.getOperand(1);
	SDValue Index = Op.getOperand(2);
	SDLoc dl(Op);
	EVT PTy = getPointerTy();
	JumpTableSDNode *JT = cast<JumpTableSDNode>(Table);
	SDValue JTI = DAG.getTargetJumpTable(JT->getIndex(), PTy);
	SDValue TableWrapper = DAG.getNode(VectorProcISD::JT_WRAPPER, dl, PTy, JTI); 
	SDValue TableMul = DAG.getNode(ISD::MUL, dl, PTy, Index, DAG.getConstant(4, PTy));
	SDValue JTAddr = DAG.getNode(ISD::ADD, dl, PTy, TableWrapper, TableMul);
	return DAG.getNode(VectorProcISD::BR_JT, dl, MVT::Other, Chain, JTAddr, JTI);
}

// SCALAR_TO_VECTOR loads the scalar register into lane 0 of the register.
// The rest of the lanes are undefined.  For simplicity, we just load the same
// value into all lanes.
SDValue VectorProcTargetLowering::
LowerSCALAR_TO_VECTOR(SDValue Op, SelectionDAG &DAG) const
{
	MVT VT = Op.getValueType().getSimpleVT();
	SDLoc dl(Op);
	return DAG.getNode(VectorProcISD::SPLAT, dl, VT, Op.getOperand(0));
}

// There is no native FNEG instruction, so we emulate it by XORing with 0x80000000
SDValue VectorProcTargetLowering::
LowerFNEG(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	MVT ResultVT = Op.getValueType().getSimpleVT();
	MVT IntermediateVT = ResultVT.isVector() ? MVT::v16i32 : MVT::i32;
	
	SDValue rhs = DAG.getConstant(0x80000000, MVT::i32);
	SDValue iconv;
	if (ResultVT.isVector())
		rhs = DAG.getNode(VectorProcISD::SPLAT, dl, MVT::v16i32, rhs);

	iconv = DAG.getNode(ISD::BITCAST, dl, IntermediateVT, Op.getOperand(0));
	SDValue flipped = DAG.getNode(ISD::XOR, dl, IntermediateVT, iconv, rhs);
	return DAG.getNode(ISD::BITCAST, dl, ResultVT, flipped);
}

// Handle unsupported floating point operations: unordered comparisons
// and equality.
SDValue VectorProcTargetLowering::
LowerSETCC(SDValue Op, SelectionDAG &DAG) const
{
	ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(2))->get();
	ISD::CondCode newCode;
	SDLoc dl(Op);

	switch (CC)
	{
		default: 
			return Op;	// No change

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
			newCode = ISD::SETOGT;
			break;
		case ISD::SETUGE:  
			newCode = ISD::SETOGE;
			break;
		case ISD::SETULT:  
			newCode = ISD::SETOLT;
			break;
		case ISD::SETULE:  
			newCode = ISD::SETOLE;
			break;
			
		// Change don't care floating point comparisons to the default CPU type
		case ISD::SETGT:  
			newCode = ISD::SETOGT;
			break;
		case ISD::SETGE:  
			newCode = ISD::SETOGE;
			break;
		case ISD::SETLT:  
			newCode = ISD::SETOLT;
			break;
		case ISD::SETLE:  
			newCode = ISD::SETOLE;
			break;
			
		// Note: there is no floating point eq/ne.  Just use integer
		// forms
		case ISD::SETUEQ:
		case ISD::SETOEQ:
			newCode = ISD::SETEQ;
			break;

		case ISD::SETUNE:
		case ISD::SETONE:
			newCode = ISD::SETNE;
			break;
	}
	
	SDValue op0 = Op.getOperand(0);
	SDValue op1 = Op.getOperand(1);
	if (newCode == ISD::SETEQ || newCode == ISD::SETNE)
	{
		// Need to bitcast so we will match
		op0 = DAG.getNode(ISD::BITCAST, dl, op0.getValueType().isVector() ? MVT::v16i32 : MVT::i32,
			op0); 
		op1 = DAG.getNode(ISD::BITCAST, dl, op1.getValueType().isVector() ? MVT::v16i32 : MVT::i32,
			op1); 
	}
	
	return DAG.getNode(ISD::SETCC, dl, Op.getValueType().getSimpleVT(), 
		op0, op1, DAG.getCondCode(newCode));
}

SDValue VectorProcTargetLowering::
LowerCTLZ_ZERO_UNDEF(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	return DAG.getNode(ISD::CTLZ, dl, Op.getValueType(), Op.getOperand(0));
}

SDValue VectorProcTargetLowering::
LowerCTTZ_ZERO_UNDEF(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);
	return DAG.getNode(ISD::CTTZ, dl, Op.getValueType(), Op.getOperand(0));
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
SDValue VectorProcTargetLowering::
LowerUINT_TO_FP(SDValue Op, SelectionDAG &DAG) const
{
	SDLoc dl(Op);

	SDValue RVal = Op.getOperand(0);
	SDValue SignedVal = DAG.getNode(ISD::SINT_TO_FP, dl, MVT::f32, RVal);
	Constant *FudgeFactor = ConstantInt::get(Type::getInt32Ty(*DAG.getContext()), 
		0x4f800000);	// UINT_MAX in float format
	SDValue CPIdx = DAG.getConstantPool(FudgeFactor, MVT::f32);
	SDValue FudgeInReg = DAG.getLoad(MVT::f32, dl, DAG.getEntryNode(), CPIdx,
		MachinePointerInfo::getConstantPool(), false, false, false, 4);
	SDValue IsNegative = DAG.getSetCC(dl, getSetCCResultType(*DAG.getContext(), 
		MVT::i32), RVal, DAG.getConstant(0, MVT::i32), ISD::SETLT);
	SDValue Adjusted = DAG.getNode(ISD::FADD, dl, MVT::f32, SignedVal, FudgeInReg);

	return DAG.getNode(VectorProcISD::SEL_COND_RESULT, dl, MVT::f32, IsNegative, 
		Adjusted, SignedVal);
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
		case ISD::BR_JT: return LowerBR_JT(Op, DAG);
		case ISD::SCALAR_TO_VECTOR: return LowerSCALAR_TO_VECTOR(Op, DAG);
		case ISD::FNEG: return LowerFNEG(Op, DAG);
		case ISD::SETCC: return LowerSETCC(Op, DAG);
		case ISD::CTLZ_ZERO_UNDEF: return LowerCTLZ_ZERO_UNDEF(Op, DAG);
		case ISD::CTTZ_ZERO_UNDEF: return LowerCTTZ_ZERO_UNDEF(Op, DAG);
		case ISD::UINT_TO_FP: return LowerUINT_TO_FP(Op, DAG);
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
	switch (MI->getOpcode())
	{
		case VectorProc::SELECTI:
		case VectorProc::SELECTF:
		case VectorProc::SELECTVI:
		case VectorProc::SELECTVF:
			return EmitSelectCC(MI, BB);

		case VectorProc::ATOMIC_LOAD_ADD:
			return EmitAtomicRMW(MI, BB, VectorProc::ADDISSS);

		case VectorProc::ATOMIC_LOAD_SUB:
			return EmitAtomicRMW(MI, BB, VectorProc::SUBISSS);
			
		case VectorProc::ATOMIC_LOAD_AND:
			return EmitAtomicRMW(MI, BB, VectorProc::ANDSSS);

		case VectorProc::ATOMIC_LOAD_OR:
			return EmitAtomicRMW(MI, BB, VectorProc::ORSSS);

		case VectorProc::ATOMIC_LOAD_XOR:
			return EmitAtomicRMW(MI, BB, VectorProc::XORSSS);
			
		case VectorProc::ATOMIC_CMP_SWAP:
			return EmitAtomicCmpSwap(MI, BB);

		default:
			llvm_unreachable("unimplemented atomic operation");
	}
}

MachineBasicBlock *
VectorProcTargetLowering::EmitSelectCC(MachineInstr *MI,
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

	BuildMI(BB, dl, TII->get(VectorProc::BTRUE)).addReg(MI->getOperand(1).getReg())
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

MachineBasicBlock *VectorProcTargetLowering::EmitAtomicRMW(MachineInstr *MI, 
	MachineBasicBlock *BB, unsigned Opcode) const
{
	const TargetInstrInfo *TII = getTargetMachine().getInstrInfo();

	unsigned dest = MI->getOperand(0).getReg();
	unsigned ptr = MI->getOperand(1).getReg();
	unsigned incr = MI->getOperand(2).getReg();
	DebugLoc dl = MI->getDebugLoc();
	MachineRegisterInfo &MRI = BB->getParent()->getRegInfo();
	unsigned scratch1 = MRI.createVirtualRegister(&VectorProc::ScalarRegRegClass);
	unsigned scratch2 = MRI.createVirtualRegister(&VectorProc::ScalarRegRegClass);
	unsigned scratch3 = MRI.createVirtualRegister(&VectorProc::ScalarRegRegClass);

	const BasicBlock *LLVM_BB = BB->getBasicBlock();
	MachineFunction *MF = BB->getParent();
	MachineFunction::iterator It = BB;
	++It;

	MachineBasicBlock *loopMBB = MF->CreateMachineBasicBlock(LLVM_BB);
	MachineBasicBlock *exitMBB = MF->CreateMachineBasicBlock(LLVM_BB);
	MF->insert(It, loopMBB);
	MF->insert(It, exitMBB);

	// Transfer the remainder of BB and its successor edges to exitMBB.
	exitMBB->splice(exitMBB->begin(), BB,
		llvm::next(MachineBasicBlock::iterator(MI)),
		BB->end());
	exitMBB->transferSuccessorsAndUpdatePHIs(BB);

	//  thisMBB:
	//   ...
	//   fallthrough --> loopMBB
	BB->addSuccessor(loopMBB);

	//  loopMBB:
	//   load.sync scratch1, ptr
	//   move dest, scratch1
	//   <op> scratch2, scratch1, incr
	//   store.sync ptr, scratch2/3
	//   iffalse scratch3 goto loopMBB
	//   fallthrough --> exitMBB
	BB = loopMBB;
	BuildMI(BB, dl, TII->get(VectorProc::LOAD_SYNC), scratch1).addReg(ptr).addImm(0);
	BuildMI(BB, dl, TII->get(VectorProc::MOVESS), dest).addReg(scratch1);
	BuildMI(BB, dl, TII->get(Opcode), scratch2).addReg(scratch1).addReg(incr);
	BuildMI(BB, dl, TII->get(VectorProc::STORE_SYNC), scratch3).addReg(scratch2)
		.addReg(ptr).addImm(0);
	BuildMI(BB, dl, TII->get(VectorProc::BFALSE)).addReg(scratch3).addMBB(loopMBB);
	BB->addSuccessor(loopMBB);
	BB->addSuccessor(exitMBB);

	//  exitMBB:
	//   ...
	BB = exitMBB;

	MI->eraseFromParent();   // The instruction is gone now.

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

  unsigned Dest    = MI->getOperand(0).getReg();
  unsigned Ptr     = MI->getOperand(1).getReg();
  unsigned OldVal  = MI->getOperand(2).getReg();
  unsigned NewVal  = MI->getOperand(3).getReg();

  unsigned Success = RegInfo.createVirtualRegister(RC);
  unsigned CmpResult = RegInfo.createVirtualRegister(RC);

  // insert new blocks after the current block
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineBasicBlock *loop1MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *loop2MBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *exitMBB = MF->CreateMachineBasicBlock(LLVM_BB);
  MachineFunction::iterator It = BB;
  ++It;
  MF->insert(It, loop1MBB);
  MF->insert(It, loop2MBB);
  MF->insert(It, exitMBB);

  // Transfer the remainder of BB and its successor edges to exitMBB.
  exitMBB->splice(exitMBB->begin(), BB,
                  llvm::next(MachineBasicBlock::iterator(MI)), BB->end());
  exitMBB->transferSuccessorsAndUpdatePHIs(BB);

  //  thisMBB:
  //    ...
  //    fallthrough --> loop1MBB
  BB->addSuccessor(loop1MBB);
  loop1MBB->addSuccessor(exitMBB);
  loop1MBB->addSuccessor(loop2MBB);
  loop2MBB->addSuccessor(loop1MBB);
  loop2MBB->addSuccessor(exitMBB);

  // loop1MBB:
  //   load.sync dest, 0(ptr)
  //   setne cmpresult, dest, oldval
  //   btrue cmpresult, exitMBB
  BB = loop1MBB;
  BuildMI(BB, DL, TII->get(VectorProc::LOAD_SYNC), Dest).addReg(Ptr).addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::SNESISSS), CmpResult).addReg(Dest).addReg(OldVal);
  BuildMI(BB, DL, TII->get(VectorProc::BTRUE)).addReg(CmpResult).addMBB(exitMBB);

  // loop2MBB:
  //   move success, newval			; need a temporary because
  //   store.sync success, 0(ptr)	; store.sync will clobber success
  //   bfalse success, loop1MBB
  BB = loop2MBB;
  BuildMI(BB, DL, TII->get(VectorProc::STORE_SYNC), Success).addReg(NewVal)
  	.addReg(Ptr).addImm(0);
  BuildMI(BB, DL, TII->get(VectorProc::BFALSE)).addReg(Success).addMBB(loop1MBB);

  MI->eraseFromParent();   // The instruction is gone now.

  return exitMBB;
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
			case 's': 
			case 'v': return C_RegisterClass;
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
			case 's':
				return std::make_pair(0U, &VectorProc::ScalarRegRegClass);

			case 'v':
				return std::make_pair(0U, &VectorProc::VectorRegRegClass);
		}
	}

	return TargetLowering::getRegForInlineAsmConstraint(Constraint, VT);
}

bool
VectorProcTargetLowering::isOffsetFoldingLegal(const GlobalAddressSDNode *GA) const {
  // The VectorProc target isn't yet aware of offsets.
  return false;
}
