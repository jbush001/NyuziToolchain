//===-- ABINyuzi.cpp --------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "ABINyuzi.h"

#include "lldb/Core/ConstString.h"
#include "lldb/Core/DataExtractor.h"
#include "lldb/Core/Error.h"
#include "lldb/Core/Log.h"
#include "lldb/Core/Module.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Core/RegisterValue.h"
#include "lldb/Core/Value.h"
#include "lldb/Core/ValueObjectConstResult.h"
#include "lldb/Core/ValueObjectRegister.h"
#include "lldb/Core/ValueObjectMemory.h"
#include "lldb/Symbol/ClangASTContext.h"
#include "lldb/Symbol/UnwindPlan.h"
#include "lldb/Target/Target.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/RegisterContext.h"
#include "lldb/Target/StackFrame.h"
#include "lldb/Target/Thread.h"

#include "llvm/ADT/Triple.h"

#include "llvm/IR/Type.h"

using namespace lldb;
using namespace lldb_private;

static RegisterInfo g_register_infos[] = 
{
	// name, altname, size, offset, encoding, format, gcc num, dwarf num, generic num, gdb num, lldb num, value regs, inval regs
    { "s00"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  0,  0, LLDB_INVALID_REGNUM,     0,  0 }, NULL, NULL },
    { "s01"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  1,  1, LLDB_INVALID_REGNUM,     1,  1 }, NULL, NULL },
    { "s02"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  2,  2, LLDB_INVALID_REGNUM,     2,  2 }, NULL, NULL },
    { "s03"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  3,  3, LLDB_INVALID_REGNUM,     3,  3 }, NULL, NULL },
    { "s04"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  4,  4, LLDB_INVALID_REGNUM,     4,  4 }, NULL, NULL },
    { "s05"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  5,  5, LLDB_INVALID_REGNUM,     5,  5 }, NULL, NULL },
    { "s06"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  6,  6, LLDB_INVALID_REGNUM,     6,  6 }, NULL, NULL },
    { "s07"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  7,  7, LLDB_INVALID_REGNUM,     7,  7 }, NULL, NULL },
    { "s08"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  8,  8, LLDB_INVALID_REGNUM,     8,  8 }, NULL, NULL },
    { "s09"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, {  9,  9, LLDB_INVALID_REGNUM,     9,  9 }, NULL, NULL },
    { "s10"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 10, 10, LLDB_INVALID_REGNUM,    10, 10 }, NULL, NULL },
    { "s11"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 11, 11, LLDB_INVALID_REGNUM,    11, 11 }, NULL, NULL },
    { "s12"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 12, 12, LLDB_INVALID_REGNUM,    12, 12 }, NULL, NULL },
    { "s13"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 13, 13, LLDB_INVALID_REGNUM,    13, 13 }, NULL, NULL },
    { "s14"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 14, 14, LLDB_INVALID_REGNUM,    14, 14 }, NULL, NULL },
    { "s15"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 15, 15, LLDB_INVALID_REGNUM,    15, 15 }, NULL, NULL },
    { "s16"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 16, 16, LLDB_INVALID_REGNUM,    16, 16 }, NULL, NULL },
    { "s17"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 17, 17, LLDB_INVALID_REGNUM,    17, 17 }, NULL, NULL },
    { "s18"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 18, 18, LLDB_INVALID_REGNUM,    18, 18 }, NULL, NULL },
    { "s19"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 19, 19, LLDB_INVALID_REGNUM,    19, 19 }, NULL, NULL },
    { "s20"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 20, 20, LLDB_INVALID_REGNUM,    20, 20 }, NULL, NULL },
    { "s21"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 21, 21, LLDB_INVALID_REGNUM,    21, 21 }, NULL, NULL },
    { "s22"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 22, 22, LLDB_INVALID_REGNUM,    22, 22 }, NULL, NULL },
    { "s23"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 23, 23, LLDB_INVALID_REGNUM,    23, 23 }, NULL, NULL },
    { "s24"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 24, 24, LLDB_INVALID_REGNUM,    24, 24 }, NULL, NULL },
    { "s25"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 25, 25, LLDB_INVALID_REGNUM,    25, 25 }, NULL, NULL },
    { "s26"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 26, 26, LLDB_INVALID_REGNUM,    26, 26 }, NULL, NULL },
    { "s27"   , "", 4, 0, eEncodingUint, eFormatAddressInfo, { 27, 27, LLDB_INVALID_REGNUM,    27, 27 }, NULL, NULL },
    { "fp"  ,"r28", 4, 0, eEncodingUint, eFormatAddressInfo, { 30, 30, LLDB_REGNUM_GENERIC_FP, 30, 30 }, NULL, NULL },
    { "sp"  ,"r29", 4, 0, eEncodingUint, eFormatAddressInfo, { 29, 29, LLDB_REGNUM_GENERIC_SP, 29, 29 }, NULL, NULL },
    { "link","r30", 4, 0, eEncodingUint, eFormatAddressInfo, { 31, 31, LLDB_REGNUM_GENERIC_RA, 31, 31 }, NULL, NULL },
    { "lr"  ,"r31", 4, 0, eEncodingUint, eFormatAddressInfo, { 31, 31, LLDB_REGNUM_GENERIC_PC, 31, 31 }, NULL, NULL },
	{ "v00"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 32, 32, LLDB_INVALID_REGNUM,    32, 32 }, NULL, NULL },
	{ "v01"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 33, 33, LLDB_INVALID_REGNUM,    33, 33 }, NULL, NULL },
	{ "v02"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 34, 34, LLDB_INVALID_REGNUM,    34, 34 }, NULL, NULL },
	{ "v03"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 35, 35, LLDB_INVALID_REGNUM,    35, 35 }, NULL, NULL },
	{ "v04"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 36, 36, LLDB_INVALID_REGNUM,    36, 36 }, NULL, NULL },
	{ "v05"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 37, 37, LLDB_INVALID_REGNUM,    37, 37 }, NULL, NULL },
	{ "v06"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 38, 38, LLDB_INVALID_REGNUM,    38, 38 }, NULL, NULL },
	{ "v07"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 39, 39, LLDB_INVALID_REGNUM,    39, 39 }, NULL, NULL },
	{ "v08"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 40, 40, LLDB_INVALID_REGNUM,    40, 40 }, NULL, NULL },
	{ "v09"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 41, 41, LLDB_INVALID_REGNUM,    41, 41 }, NULL, NULL },
	{ "v10"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 42, 42, LLDB_INVALID_REGNUM,    42, 42 }, NULL, NULL },
	{ "v11"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 43, 43, LLDB_INVALID_REGNUM,    43, 43 }, NULL, NULL },
	{ "v12"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 44, 44, LLDB_INVALID_REGNUM,    44, 44 }, NULL, NULL },
	{ "v13"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 45, 45, LLDB_INVALID_REGNUM,    45, 45 }, NULL, NULL },
	{ "v14"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 46, 46, LLDB_INVALID_REGNUM,    46, 46 }, NULL, NULL },
	{ "v15"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 47, 47, LLDB_INVALID_REGNUM,    47, 47 }, NULL, NULL },
	{ "v16"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 48, 48, LLDB_INVALID_REGNUM,    48, 48 }, NULL, NULL },
	{ "v17"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 49, 49, LLDB_INVALID_REGNUM,    49, 49 }, NULL, NULL },
	{ "v18"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 50, 50, LLDB_INVALID_REGNUM,    50, 50 }, NULL, NULL },
	{ "v19"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 51, 51, LLDB_INVALID_REGNUM,    51, 51 }, NULL, NULL },
	{ "v20"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 52, 52, LLDB_INVALID_REGNUM,    52, 52 }, NULL, NULL },
	{ "v21"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 53, 53, LLDB_INVALID_REGNUM,    53, 53 }, NULL, NULL },
	{ "v22"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 54, 54, LLDB_INVALID_REGNUM,    54, 54 }, NULL, NULL },
	{ "v23"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 55, 55, LLDB_INVALID_REGNUM,    55, 55 }, NULL, NULL },
	{ "v24"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 56, 56, LLDB_INVALID_REGNUM,    56, 56 }, NULL, NULL },
	{ "v25"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 57, 57, LLDB_INVALID_REGNUM,    57, 57 }, NULL, NULL },
	{ "v26"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 58, 58, LLDB_INVALID_REGNUM,    58, 58 }, NULL, NULL },
	{ "v27"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 59, 59, LLDB_INVALID_REGNUM,    59, 59 }, NULL, NULL },
	{ "v28"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 60, 60, LLDB_INVALID_REGNUM,    60, 60 }, NULL, NULL },
	{ "v29"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 61, 61, LLDB_INVALID_REGNUM,    61, 61 }, NULL, NULL },
	{ "v30"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 62, 62, LLDB_INVALID_REGNUM,    62, 62 }, NULL, NULL },
	{ "v31"   , "", 64, 0, eEncodingUint, eFormatAddressInfo, { 63, 63, LLDB_INVALID_REGNUM,    63, 63 }, NULL, NULL }
};

static const uint32_t k_num_register_infos = sizeof(g_register_infos)/sizeof(RegisterInfo);
static bool g_register_info_names_constified = false;

const lldb_private::RegisterInfo *
ABINyuzi::GetRegisterInfoArray ( uint32_t &count )
{
    // Make the C-string names and alt_names for the register infos into const 
    // C-string values by having the ConstString unique the names in the global
    // constant C-string pool.
    if (!g_register_info_names_constified)
    {
        g_register_info_names_constified = true;
        for (uint32_t i=0; i<k_num_register_infos; ++i)
        {
            if (g_register_infos[i].name)
                g_register_infos[i].name = ConstString(g_register_infos[i].name).GetCString();
            if (g_register_infos[i].alt_name)
                g_register_infos[i].alt_name = ConstString(g_register_infos[i].alt_name).GetCString();
        }
    }
    count = k_num_register_infos;
    return g_register_infos;
}

size_t
ABINyuzi::GetRedZoneSize () const
{
    return 0;
}

//------------------------------------------------------------------
// Static Functions
//------------------------------------------------------------------
ABISP
ABINyuzi::CreateInstance ( const ArchSpec &arch )
{
    static ABISP g_abi_sp;
    if (arch.GetTriple().getArch() == llvm::Triple::nyuzi)
    {
        if (!g_abi_sp)
            g_abi_sp.reset (new ABINyuzi);
        return g_abi_sp;
    }
    return ABISP();
}

bool
ABINyuzi::PrepareTrivialCall ( Thread &thread, 
                                      lldb::addr_t  sp    , 
                                      lldb::addr_t  pc    , 
                                      lldb::addr_t  ra    , 
                                      llvm::ArrayRef<addr_t> args ) const
{
 	// XXX implement me
  return false;
}

bool
ABINyuzi::GetArgumentValues ( Thread &thread, ValueList &values ) const
{
	// XXX implement me
  return false;
}

Error
ABINyuzi::SetReturnValueObject ( lldb::StackFrameSP &frame_sp, lldb::ValueObjectSP &new_value_sp )
{
	Error error;

	// XXX implement me
	assert(0);

  return error;
}

ValueObjectSP
ABINyuzi::GetReturnValueObjectSimple ( Thread &thread, ClangASTType &return_clang_type ) const
{
  ValueObjectSP return_valobj_sp;

	// XXX implement me
	assert(0);

  return return_valobj_sp;
}

ValueObjectSP
ABINyuzi::GetReturnValueObjectImpl ( Thread &thread, ClangASTType &return_clang_type ) const
{
  ValueObjectSP return_valobj_sp;

	// XXX implement me
	assert(0);

  return return_valobj_sp;
}

// See lib/Target/Nyuzi/NyuziFrameLowering.cpp, emitPrologue
bool
ABINyuzi::CreateFunctionEntryUnwindPlan ( UnwindPlan &unwind_plan )
{
  unwind_plan.Clear();
  unwind_plan.SetRegisterKind(eRegisterKindDWARF);
  unwind_plan.SetReturnAddressRegister(LLDB_REGNUM_GENERIC_RA);
  
  UnwindPlan::RowSP row(new UnwindPlan::Row);

  // Our Call Frame Address is the stack pointer value
  row->GetCFAValue().SetIsRegisterPlusOffset(29, 0);

  unwind_plan.AppendRow(row);
  
  unwind_plan.SetSourceName("nyuzi at-func-entry default");
  unwind_plan.SetSourcedFromCompiler(eLazyBoolNo);
  unwind_plan.SetReturnAddressRegister(30);
  return true;
}

bool
ABINyuzi::CreateDefaultUnwindPlan ( UnwindPlan &unwind_plan )
{
  unwind_plan.Clear();
  unwind_plan.SetRegisterKind(eRegisterKindDWARF);
  UnwindPlan::RowSP row(new UnwindPlan::Row);

  row->GetCFAValue().SetIsRegisterPlusOffset(29, 0);

  unwind_plan.AppendRow(row);
  unwind_plan.SetSourceName("nyuzi default unwind plan");
  unwind_plan.SetSourcedFromCompiler(eLazyBoolNo);
	unwind_plan.SetUnwindPlanValidAtAllInstructions(eLazyBoolNo);
  unwind_plan.SetReturnAddressRegister(30);
  return true;
}

// Return if a register is caller saved
// See lib/Target/Nyuzi/NyuziCallingConv.td
// PC must be marked not volatile.
bool
ABINyuzi::RegisterIsVolatile ( const RegisterInfo *reg_info )
{
  int reg = reg_info->kinds[eRegisterKindDWARF];
  if (reg == 30)  // link register
    return true;

	if ((reg >= 24 && reg <= 31) || reg >= 26 + 32)
		return false;
	
	return true;
}

void
ABINyuzi::Initialize( void )
{
    PluginManager::RegisterPlugin
    (
        GetPluginNameStatic(), 
        "Nyuzi ABI",
        CreateInstance
    );
}

void
ABINyuzi::Terminate( void )
{
    PluginManager::UnregisterPlugin( CreateInstance );
}

lldb_private::ConstString
ABINyuzi::GetPluginNameStatic()
{
    static ConstString g_name( "nyuzi" );
    return g_name;
}

lldb_private::ConstString
ABINyuzi::GetPluginName( void )
{
    return GetPluginNameStatic();
}

uint32_t
ABINyuzi::GetPluginVersion( void )
{
    return 1;
}

lldb::ValueObjectSP
ABINyuzi::GetReturnValueObjectImpl( lldb_private::Thread &thread, llvm::Type &retType ) const
{
    Value value;
    ValueObjectSP vObjSP;
	
	// XXX implement me

    return vObjSP;
}
