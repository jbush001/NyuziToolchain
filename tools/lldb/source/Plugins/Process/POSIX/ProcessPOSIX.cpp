//===-- ProcessPOSIX.cpp ----------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

// C Includes
#include <errno.h>

// C++ Includes
// Other libraries and framework includes
#include "lldb/Breakpoint/BreakpointLocation.h"
#include "lldb/Breakpoint/Watchpoint.h"
#include "lldb/Core/Module.h"
#include "lldb/Core/ModuleSpec.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Core/State.h"
#include "lldb/Host/FileSpec.h"
#include "lldb/Host/Host.h"
#include "lldb/Symbol/ObjectFile.h"
#include "lldb/Target/DynamicLoader.h"
#include "lldb/Target/Platform.h"
#include "lldb/Target/Target.h"

#include "ProcessPOSIX.h"
#include "ProcessPOSIXLog.h"
#include "Plugins/Process/Utility/InferiorCallPOSIX.h"
#include "Plugins/Process/Linux/ProcessMonitor.h"
#include "POSIXThread.h"

#include "lldb/Host/posix/Fcntl.h"

using namespace lldb;
using namespace lldb_private;

//------------------------------------------------------------------------------
// Constructors and destructors.

ProcessPOSIX::ProcessPOSIX(Target& target, Listener &listener, UnixSignalsSP &unix_signals_sp)
    : Process(target, listener, unix_signals_sp),
      m_byte_order(lldb::endian::InlHostByteOrder()),
      m_monitor(NULL),
      m_module(NULL),
      m_message_mutex (Mutex::eMutexTypeRecursive),
      m_exit_now(false),
      m_seen_initial_stop()
{
    // FIXME: Putting this code in the ctor and saving the byte order in a
    // member variable is a hack to avoid const qual issues in GetByteOrder.
    lldb::ModuleSP module = GetTarget().GetExecutableModule();
    if (module && module->GetObjectFile())
        m_byte_order = module->GetObjectFile()->GetByteOrder();
}

ProcessPOSIX::~ProcessPOSIX()
{
    delete m_monitor;
}

//------------------------------------------------------------------------------
// Process protocol.
void
ProcessPOSIX::Finalize()
{
  Process::Finalize();

  if (m_monitor)
    m_monitor->StopMonitor();
}

bool
ProcessPOSIX::CanDebug(Target &target, bool plugin_specified_by_name)
{
    // For now we are just making sure the file exists for a given module
    ModuleSP exe_module_sp(target.GetExecutableModule());
    if (exe_module_sp.get())
        return exe_module_sp->GetFileSpec().Exists();
    // If there is no executable module, we return true since we might be preparing to attach.
    return true;
}

Error
ProcessPOSIX::DoAttachToProcessWithID (lldb::pid_t pid,  const ProcessAttachInfo &attach_info)
{
    Error error;
    assert(m_monitor == NULL);

    Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet (POSIX_LOG_PROCESS));
    if (log && log->GetMask().Test(POSIX_LOG_VERBOSE))
        log->Printf ("ProcessPOSIX::%s(pid = %" PRIi64 ")", __FUNCTION__, GetID());

    m_monitor = new ProcessMonitor(this, pid, error);

    if (!error.Success())
        return error;

    PlatformSP platform_sp (m_target.GetPlatform ());
    assert (platform_sp.get());
    if (!platform_sp)
        return error;  // FIXME: Detatch?

    // Find out what we can about this process
    ProcessInstanceInfo process_info;
    platform_sp->GetProcessInfo (pid, process_info);

    // Resolve the executable module
    ModuleSP exe_module_sp;
    FileSpecList executable_search_paths (Target::GetDefaultExecutableSearchPaths());
    ModuleSpec exe_module_spec(process_info.GetExecutableFile(), m_target.GetArchitecture());
    error = platform_sp->ResolveExecutable(exe_module_spec,
                                           exe_module_sp,
                                           executable_search_paths.GetSize() ? &executable_search_paths : NULL);
    if (!error.Success())
        return error;

    // Fix the target architecture if necessary
    const ArchSpec &module_arch = exe_module_sp->GetArchitecture();
    if (module_arch.IsValid() && !m_target.GetArchitecture().IsExactMatch(module_arch))
        m_target.SetArchitecture(module_arch);

    // Initialize the target module list
    m_target.SetExecutableModule (exe_module_sp, true);

    SetSTDIOFileDescriptor(m_monitor->GetTerminalFD());

    SetID(pid);

    return error;
}

Error
ProcessPOSIX::WillLaunch(Module* module)
{
    Error error;
    return error;
}

FileSpec
ProcessPOSIX::GetFileSpec(const lldb_private::FileAction *file_action,
                          const FileSpec &default_file_spec,
                          const FileSpec &dbg_pts_file_spec)
{
    FileSpec file_spec{};

    if (file_action && file_action->GetAction() == FileAction::eFileActionOpen)
    {
        file_spec = file_action->GetFileSpec();
        // By default the stdio paths passed in will be pseudo-terminal
        // (/dev/pts). If so, convert to using a different default path
        // instead to redirect I/O to the debugger console. This should
        // also handle user overrides to /dev/null or a different file.
        if (!file_spec || file_spec == dbg_pts_file_spec)
            file_spec = default_file_spec;
    }
    return file_spec;
}

Error
ProcessPOSIX::DoLaunch (Module *module,
                        ProcessLaunchInfo &launch_info)
{
    Error error;
    assert(m_monitor == NULL);

    FileSpec working_dir = launch_info.GetWorkingDirectory();
    if (working_dir &&
            (!working_dir.ResolvePath() ||
             working_dir.GetFileType() != FileSpec::eFileTypeDirectory))
    {
        error.SetErrorStringWithFormat("No such file or directory: %s",
                working_dir.GetCString());
        return error;
    }

    SetPrivateState(eStateLaunching);

    const lldb_private::FileAction *file_action;

    // Default of empty will mean to use existing open file descriptors
    FileSpec stdin_file_spec{};
    FileSpec stdout_file_spec{};
    FileSpec stderr_file_spec{};

    const FileSpec dbg_pts_file_spec{launch_info.GetPTY().GetSlaveName(NULL,0), false};

    file_action = launch_info.GetFileActionForFD (STDIN_FILENO);
    stdin_file_spec = GetFileSpec(file_action, stdin_file_spec, dbg_pts_file_spec);

    file_action = launch_info.GetFileActionForFD (STDOUT_FILENO);
    stdout_file_spec = GetFileSpec(file_action, stdout_file_spec, dbg_pts_file_spec);

    file_action = launch_info.GetFileActionForFD (STDERR_FILENO);
    stderr_file_spec = GetFileSpec(file_action, stderr_file_spec, dbg_pts_file_spec);

    m_monitor = new ProcessMonitor(this,
                                   module,
                                   launch_info.GetArguments().GetConstArgumentVector(),
                                   launch_info.GetEnvironmentEntries().GetConstArgumentVector(),
                                   stdin_file_spec,
                                   stdout_file_spec,
                                   stderr_file_spec,
                                   working_dir,
                                   launch_info,
                                   error);

    m_module = module;

    if (!error.Success())
        return error;

    int terminal = m_monitor->GetTerminalFD();
    if (terminal >= 0) {
        // The reader thread will close the file descriptor when done, so we pass it a copy.
        int stdio = fcntl(terminal, F_DUPFD_CLOEXEC, 0);
        if (stdio == -1) {
            error.SetErrorToErrno();
            return error;
        }
        SetSTDIOFileDescriptor(stdio);
    }

    SetID(m_monitor->GetPID());
    return error;
}

void
ProcessPOSIX::DidLaunch()
{
}

Error
ProcessPOSIX::DoResume()
{
    StateType state = GetPrivateState();

    assert(state == eStateStopped);

    SetPrivateState(eStateRunning);

    bool did_resume = false;

    Mutex::Locker lock(m_thread_list.GetMutex());

    uint32_t thread_count = m_thread_list.GetSize(false);
    for (uint32_t i = 0; i < thread_count; ++i)
    {
        POSIXThread *thread = static_cast<POSIXThread*>(
            m_thread_list.GetThreadAtIndex(i, false).get());
        did_resume = thread->Resume() || did_resume;
    }
    assert(did_resume && "Process resume failed!");

    return Error();
}

addr_t
ProcessPOSIX::GetImageInfoAddress()
{
    Target *target = &GetTarget();
    ObjectFile *obj_file = target->GetExecutableModule()->GetObjectFile();
    Address addr = obj_file->GetImageInfoAddress(target);

    if (addr.IsValid())
        return addr.GetLoadAddress(target);
    return LLDB_INVALID_ADDRESS;
}

Error
ProcessPOSIX::DoHalt(bool &caused_stop)
{
    Error error;

    if (IsStopped())
    {
        caused_stop = false;
    }
    else if (kill(GetID(), SIGSTOP))
    {
        caused_stop = false;
        error.SetErrorToErrno();
    }
    else
    {
        caused_stop = true;
    }
    return error;
}

Error
ProcessPOSIX::DoSignal(int signal)
{
    Error error;

    if (kill(GetID(), signal))
        error.SetErrorToErrno();

    return error;
}

Error
ProcessPOSIX::DoDestroy()
{
    Error error;

    if (!HasExited())
    {
        assert(m_monitor);
        m_exit_now = true;
        if (GetID() == LLDB_INVALID_PROCESS_ID)
        {
            error.SetErrorString("invalid process id");
            return error;
        }
        if (!m_monitor->Kill())
        {
            error.SetErrorToErrno();
            return error;
        }

        SetPrivateState(eStateExited);
    }

    return error;
}

void
ProcessPOSIX::DoDidExec()
{
    Target *target = &GetTarget();
    if (target)
    {
        PlatformSP platform_sp (target->GetPlatform());
        assert (platform_sp.get());
        if (platform_sp)
        {
            ProcessInstanceInfo process_info;
            platform_sp->GetProcessInfo(GetID(), process_info);
            ModuleSP exe_module_sp;
            ModuleSpec exe_module_spec(process_info.GetExecutableFile(), target->GetArchitecture());
            FileSpecList executable_search_paths (Target::GetDefaultExecutableSearchPaths());
            Error error = platform_sp->ResolveExecutable(exe_module_spec,
                                                         exe_module_sp,
                                                         executable_search_paths.GetSize() ? &executable_search_paths : NULL);
            if (!error.Success())
                return;
            target->SetExecutableModule(exe_module_sp, true);
        }
    }
}

void
ProcessPOSIX::SendMessage(const ProcessMessage &message)
{
    Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet (POSIX_LOG_PROCESS));

    Mutex::Locker lock(m_message_mutex);

    Mutex::Locker thread_lock(m_thread_list.GetMutex());

    POSIXThread *thread = static_cast<POSIXThread*>(
        m_thread_list.FindThreadByID(message.GetTID(), false).get());

    switch (message.GetKind())
    {
    case ProcessMessage::eInvalidMessage:
        return;

    case ProcessMessage::eAttachMessage:
        SetPrivateState(eStateStopped);
        return;

    case ProcessMessage::eLimboMessage:
        assert(thread);
        thread->SetState(eStateStopped);
        if (message.GetTID() == GetID())
        {
            m_exit_status = message.GetExitStatus();
            if (m_exit_now)
            {
                SetPrivateState(eStateExited);
                m_monitor->Detach(GetID());
            }
            else
            {
                StopAllThreads(message.GetTID());
                SetPrivateState(eStateStopped);
            }
        }
        else
        {
            StopAllThreads(message.GetTID());
            SetPrivateState(eStateStopped);
        }
        break;

    case ProcessMessage::eExitMessage:
        if (thread != nullptr)
            thread->SetState(eStateExited);
        else
        {
            if (log)
                log->Warning ("ProcessPOSIX::%s eExitMessage for TID %" PRIu64 " failed to find a thread to mark as eStateExited, ignoring", __FUNCTION__, message.GetTID ());
        }

        // FIXME: I'm not sure we need to do this.
        if (message.GetTID() == GetID())
        {
            SetExitStatus(message.GetExitStatus(), NULL);
        }
        else if (!IsAThreadRunning())
            SetPrivateState(eStateStopped);
        break;

    case ProcessMessage::eSignalMessage:
    case ProcessMessage::eSignalDeliveredMessage:
        if (message.GetSignal() == SIGSTOP &&
            AddThreadForInitialStopIfNeeded(message.GetTID()))
            return;
        // Intentional fall-through

    case ProcessMessage::eBreakpointMessage:
    case ProcessMessage::eTraceMessage:
    case ProcessMessage::eWatchpointMessage:
    case ProcessMessage::eCrashMessage:
        assert(thread);
        thread->SetState(eStateStopped);
        StopAllThreads(message.GetTID());
        SetPrivateState(eStateStopped);
        break;

    case ProcessMessage::eNewThreadMessage:
    {
        lldb::tid_t  new_tid = message.GetChildTID();
        if (WaitingForInitialStop(new_tid))
        {
            m_monitor->WaitForInitialTIDStop(new_tid);
        }
        assert(thread);
        thread->SetState(eStateStopped);
        StopAllThreads(message.GetTID());
        SetPrivateState(eStateStopped);
        break;
    }

    case ProcessMessage::eExecMessage:
    {
        assert(thread);
        thread->SetState(eStateStopped);
        StopAllThreads(message.GetTID());
        SetPrivateState(eStateStopped);
        break;
    }
    }


    m_message_queue.push(message);
}

void 
ProcessPOSIX::StopAllThreads(lldb::tid_t stop_tid)
{
    // FIXME: Will this work the same way on FreeBSD and Linux?
}

bool
ProcessPOSIX::AddThreadForInitialStopIfNeeded(lldb::tid_t stop_tid)
{
    bool added_to_set = false;
    ThreadStopSet::iterator it = m_seen_initial_stop.find(stop_tid);
    if (it == m_seen_initial_stop.end())
    {
        m_seen_initial_stop.insert(stop_tid);
        added_to_set = true;
    }
    return added_to_set;
}

bool
ProcessPOSIX::WaitingForInitialStop(lldb::tid_t stop_tid)
{
    return (m_seen_initial_stop.find(stop_tid) == m_seen_initial_stop.end());
}

POSIXThread *
ProcessPOSIX::CreateNewPOSIXThread(lldb_private::Process &process, lldb::tid_t tid)
{
    return new POSIXThread(process, tid);
}

void
ProcessPOSIX::RefreshStateAfterStop()
{
    Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet (POSIX_LOG_PROCESS));
    if (log && log->GetMask().Test(POSIX_LOG_VERBOSE))
        log->Printf ("ProcessPOSIX::%s(), message_queue size = %d", __FUNCTION__, (int)m_message_queue.size());

    Mutex::Locker lock(m_message_mutex);

    // This method used to only handle one message.  Changing it to loop allows
    // it to handle the case where we hit a breakpoint while handling a different
    // breakpoint.
    while (!m_message_queue.empty())
    {
        ProcessMessage &message = m_message_queue.front();

        // Resolve the thread this message corresponds to and pass it along.
        lldb::tid_t tid = message.GetTID();
        if (log)
            log->Printf ("ProcessPOSIX::%s(), message_queue size = %d, pid = %" PRIi64, __FUNCTION__, (int)m_message_queue.size(), tid);

        if (message.GetKind() == ProcessMessage::eNewThreadMessage)
        {
            if (log)
                log->Printf ("ProcessPOSIX::%s() adding thread, tid = %" PRIi64, __FUNCTION__, message.GetChildTID());
            lldb::tid_t child_tid = message.GetChildTID();
            ThreadSP thread_sp;
            thread_sp.reset(CreateNewPOSIXThread(*this, child_tid));

            Mutex::Locker lock(m_thread_list.GetMutex());

            m_thread_list.AddThread(thread_sp);
        }

        m_thread_list.RefreshStateAfterStop();

        POSIXThread *thread = static_cast<POSIXThread*>(
            GetThreadList().FindThreadByID(tid, false).get());
        if (thread)
            thread->Notify(message);

        if (message.GetKind() == ProcessMessage::eExitMessage)
        {
            // FIXME: We should tell the user about this, but the limbo message is probably better for that.
            if (log)
                log->Printf ("ProcessPOSIX::%s() removing thread, tid = %" PRIi64, __FUNCTION__, tid);

            Mutex::Locker lock(m_thread_list.GetMutex());

            ThreadSP thread_sp = m_thread_list.RemoveThreadByID(tid, false);
            thread_sp.reset();
            m_seen_initial_stop.erase(tid);
        }

        m_message_queue.pop();
    }
}

bool
ProcessPOSIX::IsAlive()
{
    StateType state = GetPrivateState();
    return state != eStateDetached
        && state != eStateExited
        && state != eStateInvalid
        && state != eStateUnloaded;
}

size_t
ProcessPOSIX::DoReadMemory(addr_t vm_addr,
                           void *buf, size_t size, Error &error)
{
    assert(m_monitor);
    return m_monitor->ReadMemory(vm_addr, buf, size, error);
}

size_t
ProcessPOSIX::DoWriteMemory(addr_t vm_addr, const void *buf, size_t size,
                            Error &error)
{
    assert(m_monitor);
    return m_monitor->WriteMemory(vm_addr, buf, size, error);
}

addr_t
ProcessPOSIX::DoAllocateMemory(size_t size, uint32_t permissions,
                               Error &error)
{
    addr_t allocated_addr = LLDB_INVALID_ADDRESS;

    unsigned prot = 0;
    if (permissions & lldb::ePermissionsReadable)
        prot |= eMmapProtRead;
    if (permissions & lldb::ePermissionsWritable)
        prot |= eMmapProtWrite;
    if (permissions & lldb::ePermissionsExecutable)
        prot |= eMmapProtExec;

    if (InferiorCallMmap(this, allocated_addr, 0, size, prot,
                         eMmapFlagsAnon | eMmapFlagsPrivate, -1, 0)) {
        m_addr_to_mmap_size[allocated_addr] = size;
        error.Clear();
    } else {
        allocated_addr = LLDB_INVALID_ADDRESS;
        error.SetErrorStringWithFormat("unable to allocate %zu bytes of memory with permissions %s", size, GetPermissionsAsCString (permissions));
    }

    return allocated_addr;
}

Error
ProcessPOSIX::DoDeallocateMemory(lldb::addr_t addr)
{
    Error error;
    MMapMap::iterator pos = m_addr_to_mmap_size.find(addr);
    if (pos != m_addr_to_mmap_size.end() &&
        InferiorCallMunmap(this, addr, pos->second))
        m_addr_to_mmap_size.erase (pos);
    else
        error.SetErrorStringWithFormat("unable to deallocate memory at 0x%" PRIx64, addr);

    return error;
}

size_t
ProcessPOSIX::GetSoftwareBreakpointTrapOpcode(BreakpointSite* bp_site)
{
    static const uint8_t g_aarch64_opcode[] = { 0x00, 0x00, 0x20, 0xD4 };
    static const uint8_t g_i386_opcode[] = { 0xCC };

    ArchSpec arch = GetTarget().GetArchitecture();
    const uint8_t *opcode = NULL;
    size_t opcode_size = 0;

    switch (arch.GetMachine())
    {
    default:
        assert(false && "CPU type not supported!");
        break;

    case llvm::Triple::arm:
        {
            // The ARM reference recommends the use of 0xe7fddefe and 0xdefe
            // but the linux kernel does otherwise.
            static const uint8_t g_arm_breakpoint_opcode[] = { 0xf0, 0x01, 0xf0, 0xe7 };
            static const uint8_t g_thumb_breakpoint_opcode[] = { 0x01, 0xde };

            lldb::BreakpointLocationSP bp_loc_sp (bp_site->GetOwnerAtIndex (0));
            AddressClass addr_class = eAddressClassUnknown;

            if (bp_loc_sp)
                addr_class = bp_loc_sp->GetAddress ().GetAddressClass ();

            if (addr_class == eAddressClassCodeAlternateISA
                || (addr_class == eAddressClassUnknown
                    && bp_loc_sp->GetAddress().GetOffset() & 1))
            {
                opcode = g_thumb_breakpoint_opcode;
                opcode_size = sizeof(g_thumb_breakpoint_opcode);
            }
            else
            {
                opcode = g_arm_breakpoint_opcode;
                opcode_size = sizeof(g_arm_breakpoint_opcode);
            }
        }
        break;
    case llvm::Triple::aarch64:
        opcode = g_aarch64_opcode;
        opcode_size = sizeof(g_aarch64_opcode);
        break;

    case llvm::Triple::x86:
    case llvm::Triple::x86_64:
        opcode = g_i386_opcode;
        opcode_size = sizeof(g_i386_opcode);
        break;
    }

    bp_site->SetTrapOpcode(opcode, opcode_size);
    return opcode_size;
}

Error
ProcessPOSIX::EnableBreakpointSite(BreakpointSite *bp_site)
{
    return EnableSoftwareBreakpoint(bp_site);
}

Error
ProcessPOSIX::DisableBreakpointSite(BreakpointSite *bp_site)
{
    return DisableSoftwareBreakpoint(bp_site);
}

Error
ProcessPOSIX::EnableWatchpoint(Watchpoint *wp, bool notify)
{
    Error error;
    if (wp)
    {
        user_id_t watchID = wp->GetID();
        addr_t addr = wp->GetLoadAddress();
        Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet(POSIX_LOG_WATCHPOINTS));
        if (log)
            log->Printf ("ProcessPOSIX::EnableWatchpoint(watchID = %" PRIu64 ")",
                         watchID);
        if (wp->IsEnabled())
        {
            if (log)
                log->Printf("ProcessPOSIX::EnableWatchpoint(watchID = %" PRIu64
                            ") addr = 0x%8.8" PRIx64 ": watchpoint already enabled.",
                            watchID, (uint64_t)addr);
            return error;
        }

        // Try to find a vacant watchpoint slot in the inferiors' main thread
        uint32_t wp_hw_index = LLDB_INVALID_INDEX32;
        Mutex::Locker lock(m_thread_list.GetMutex());
        POSIXThread *thread = static_cast<POSIXThread*>(
                               m_thread_list.GetThreadAtIndex(0, false).get());

        if (thread)
            wp_hw_index = thread->FindVacantWatchpointIndex();

        if (wp_hw_index == LLDB_INVALID_INDEX32)
        {
            error.SetErrorString("Setting hardware watchpoint failed.");
        }
        else
        {
            wp->SetHardwareIndex(wp_hw_index);
            bool wp_enabled = true;
            uint32_t thread_count = m_thread_list.GetSize(false);
            for (uint32_t i = 0; i < thread_count; ++i)
            {
                thread = static_cast<POSIXThread*>(
                         m_thread_list.GetThreadAtIndex(i, false).get());
                if (thread)
                    wp_enabled &= thread->EnableHardwareWatchpoint(wp);
                else
                    wp_enabled = false;
            }
            if (wp_enabled)
            {
                wp->SetEnabled(true, notify);
                return error;
            }
            else
            {
                // Watchpoint enabling failed on at least one
                // of the threads so roll back all of them
                DisableWatchpoint(wp, false);
                error.SetErrorString("Setting hardware watchpoint failed");
            }
        }
    }
    else
        error.SetErrorString("Watchpoint argument was NULL.");
    return error;
}

Error
ProcessPOSIX::DisableWatchpoint(Watchpoint *wp, bool notify)
{
    Error error;
    if (wp)
    {
        user_id_t watchID = wp->GetID();
        addr_t addr = wp->GetLoadAddress();
        Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet(POSIX_LOG_WATCHPOINTS));
        if (log)
            log->Printf("ProcessPOSIX::DisableWatchpoint(watchID = %" PRIu64 ")",
                        watchID);
        if (!wp->IsEnabled())
        {
            if (log)
                log->Printf("ProcessPOSIX::DisableWatchpoint(watchID = %" PRIu64
                            ") addr = 0x%8.8" PRIx64 ": watchpoint already disabled.",
                            watchID, (uint64_t)addr);
            // This is needed (for now) to keep watchpoints disabled correctly
            wp->SetEnabled(false, notify);
            return error;
        }

        if (wp->IsHardware())
        {
            bool wp_disabled = true;
            Mutex::Locker lock(m_thread_list.GetMutex());
            uint32_t thread_count = m_thread_list.GetSize(false);
            for (uint32_t i = 0; i < thread_count; ++i)
            {
                POSIXThread *thread = static_cast<POSIXThread*>(
                                      m_thread_list.GetThreadAtIndex(i, false).get());
                if (thread)
                    wp_disabled &= thread->DisableHardwareWatchpoint(wp);
                else
                    wp_disabled = false;
            }
            if (wp_disabled)
            {
                wp->SetHardwareIndex(LLDB_INVALID_INDEX32);
                wp->SetEnabled(false, notify);
                return error;
            }
            else
                error.SetErrorString("Disabling hardware watchpoint failed");
        }
    }
    else
        error.SetErrorString("Watchpoint argument was NULL.");
    return error;
}

Error
ProcessPOSIX::GetWatchpointSupportInfo(uint32_t &num)
{
    Error error;
    Mutex::Locker lock(m_thread_list.GetMutex());
    POSIXThread *thread = static_cast<POSIXThread*>(
                          m_thread_list.GetThreadAtIndex(0, false).get());
    if (thread)
        num = thread->NumSupportedHardwareWatchpoints();
    else
        error.SetErrorString("Process does not exist.");
    return error;
}

Error
ProcessPOSIX::GetWatchpointSupportInfo(uint32_t &num, bool &after)
{
    Error error = GetWatchpointSupportInfo(num);
    // Watchpoints trigger and halt the inferior after
    // the corresponding instruction has been executed.
    after = true;
    return error;
}

uint32_t
ProcessPOSIX::UpdateThreadListIfNeeded()
{
    Mutex::Locker lock(m_thread_list.GetMutex());
    // Do not allow recursive updates.
    return m_thread_list.GetSize(false);
}

bool
ProcessPOSIX::UpdateThreadList(ThreadList &old_thread_list, ThreadList &new_thread_list)
{
    Log *log (ProcessPOSIXLog::GetLogIfAllCategoriesSet (POSIX_LOG_THREAD));
    if (log && log->GetMask().Test(POSIX_LOG_VERBOSE))
        log->Printf ("ProcessPOSIX::%s() (pid = %" PRIi64 ")", __FUNCTION__, GetID());

    bool has_updated = false;
    // Update the process thread list with this new thread.
    // FIXME: We should be using tid, not pid.
    assert(m_monitor);
    ThreadSP thread_sp (old_thread_list.FindThreadByID (GetID(), false));
    if (!thread_sp) {
        thread_sp.reset(CreateNewPOSIXThread(*this, GetID()));
        has_updated = true;
    }

    if (log && log->GetMask().Test(POSIX_LOG_VERBOSE))
        log->Printf ("ProcessPOSIX::%s() updated pid = %" PRIi64, __FUNCTION__, GetID());
    new_thread_list.AddThread(thread_sp);

    return has_updated; // the list has been updated
}

ByteOrder
ProcessPOSIX::GetByteOrder() const
{
    // FIXME: We should be able to extract this value directly.  See comment in
    // ProcessPOSIX().
    return m_byte_order;
}

size_t
ProcessPOSIX::PutSTDIN(const char *buf, size_t len, Error &error)
{
    ssize_t status;
    if ((status = write(m_monitor->GetTerminalFD(), buf, len)) < 0) 
    {
        error.SetErrorToErrno();
        return 0;
    }
    return status;
}

//------------------------------------------------------------------------------
// Utility functions.

bool
ProcessPOSIX::HasExited()
{
    switch (GetPrivateState())
    {
    default:
        break;

    case eStateDetached:
    case eStateExited:
        return true;
    }

    return false;
}

bool
ProcessPOSIX::IsStopped()
{
    switch (GetPrivateState())
    {
    default:
        break;

    case eStateStopped:
    case eStateCrashed:
    case eStateSuspended:
        return true;
    }

    return false;
}

bool
ProcessPOSIX::IsAThreadRunning()
{
    bool is_running = false;
    Mutex::Locker lock(m_thread_list.GetMutex());
    uint32_t thread_count = m_thread_list.GetSize(false);
    for (uint32_t i = 0; i < thread_count; ++i)
    {
        POSIXThread *thread = static_cast<POSIXThread*>(
            m_thread_list.GetThreadAtIndex(i, false).get());
        StateType thread_state = thread->GetState();
        if (thread_state == eStateRunning || thread_state == eStateStepping)
        {
            is_running = true;
            break;
        }
    }
    return is_running;
}

const DataBufferSP
ProcessPOSIX::GetAuxvData ()
{
    // If we're the local platform, we can ask the host for auxv data.
    PlatformSP platform_sp = m_target.GetPlatform ();
    if (platform_sp && platform_sp->IsHost ())
        return lldb_private::Host::GetAuxvData(this);

    // Somewhat unexpected - the process is not running locally or we don't have a platform.
    assert (false && "no platform or not the host - how did we get here with ProcessPOSIX?");
    return DataBufferSP ();
}
