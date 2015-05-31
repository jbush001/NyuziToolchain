""" SWIG creates Python C++ Script Bridge wrapper code Windows/LINUX/OSX platform

    --------------------------------------------------------------------------
    File:           buildSwigWrapperClasses.py

    Overview:       Python script(s) to build the SWIG Python C++ Script
                    Bridge wrapper code on the Windows/LINUX/OSX platform.
                    The Python scripts are equivalent to the shell script (.sh)
                    files.
                    For each scripting language lib lldb supports, we need to
                    create the appropriate Script Bridge wrapper classes for
                    that language so that users can call Script Bridge
                    functions from within the script interpreter.
                    We use SWIG to help create the appropriate wrapper
                    classes/functions for the scripting language.  In some
                    cases the file generated by SWIG may need some tweaking
                    before it is completely ready to use.

    Gotchas:        For Windows OS it is assumed the SWIG executable can be
                    found in the %PATH% environmental variable.

    Copyright:      None.
    --------------------------------------------------------------------------

"""

# Python modules:
import sys      # Provide argument parsing
import os       # Provide directory and file handling

# Third party modules:

# In-house modules:
import utilsArgsParse   # Parse and validate this script's input arguments
import utilsOsType      # Determine the OS type this script is running on
import utilsDebug       # Debug Python scripts

# Instantiations:
gbDbgVerbose = False;           # True = Turn on script function tracing, False = off.
gbDbgFlag = False;              # Global debug mode flag, set by input parameter
                                # --dbgFlag. True = operate in debug mode.
gbMakeFileFlag = False;         # True = yes called from makefile system, False = not.
gbSwigGenDepFileFlag = False;   # True = SWIG generate a dependency file.

# User facing text:
strMsgErrorNoMain = "Program called by another Python script not allowed";
strExitMsgSuccess = "Program successful";
strExitMsgError = "Program error: ";
strParameter = "Parameter: ";
strMsgErrorOsTypeUnknown = "Unable to determine OS type"
strSwigFileFound = "Found the \'lldb.swig\' file\n";
strSwigFileFoundNotFound = "Unable to locate the file \'%s\'"
strSwigExeFileNotFound = "Unable to locate the SWIG executable file \'swig\'";
strSwigScriptDirNotFound = "Unable to locate the SWIG script directory \'/script\'";
strSwigScriptNotFound = "Unable to locate the SWIG script file \'%s\' in \'%s\'. Is it a script directory?";
strSwigScriptLangFound = "Found \'%s\' build script.";
strSwigScriptLangsFound = "Found the following script languages:";
strSwigExecuteMsg = "Executing \'%s\' build script...";
strSwigExecuteError = "Executing \'%s\' build script failed: ";
strHelpInfo = "\
Python script(s) to build the SWIG Python C++ Script \n\
Bridge wrapper code on various platforms.  The Python \n\
scripts are equivalent to the shell script (.sh) files \n\
run on others platforms.\n\
Args:   -h      (optional) Print help information on this program.\n\
    -d      (optional) Determines whether or not this script\n\
            outputs additional information when running.\n\
    -m      (optional) Specify called from Makefile system.\n\
    -M      (optional) Specify want SWIG to generate a dependency \n\
            file.\n\
    --srcRoot=  The root of the lldb source tree.\n\
    --targetDir=    Where the lldb framework/shared library gets put.\n\
    --cfgBldDir=    (optional) Where the build-swig-Python-LLDB.py program \n\
            will put the lldb.py file it generated from running\n\
            SWIG.\n\
    --prefix=   (optional) Is the root directory used to determine where\n\
            third-party modules for scripting languages should\n\
            be installed. Where non-Darwin systems want to put\n\
            the .py and .so files so that Python can find them\n\
            automatically. Python install directory.\n\
    --argsFile= The args are read from a file instead of the\n\
            command line. Other command line args are ignored.\n\
    --swigExecutable=   (optional) Full path of swig executable.\n\
\n\
Usage:\n\
    buildSwigWrapperClasses.py --srcRoot=ADirPath --targetDir=ADirPath\n\
    --cfgBldDir=ADirPath --prefix=ADirPath --swigExecutable=ADirPath -m -d\n\
\n\
"; #TAG_PROGRAM_HELP_INFO
strHelpInfoExtraWindows = "\
On the Windows platform the PATH environmental variable needs to be \n\
extended to include the installed SWIG executable path so it can be \n\
be found by this Python script. The SWIG executable name is 'swig'."
strHelpInfoExtraNonWindows = "\
This Python script looks for the SWIG executable 'swig' in the following \n\
directories '/usr/bin', '/usr/local/bin'. If not found the script will \n\
abort.";

#++---------------------------------------------------------------------------
# Details:  Retrieve the script -h help information based on the OS currently.
# Args:     None.
# Returns:  Str - Help Text.
# Throws:   None.
#--
def get_help_information():
    strHelpMsg = strHelpInfo;

    eOSType = utilsOsType.determine_os_type();
    if eOSType == utilsOsType.EnumOsType.Windows:
        strHelpMsg += strHelpInfoExtraWindows;
    else:
        strHelpMsg += strHelpInfoExtraNonWindows;

    return strHelpMsg;

#++---------------------------------------------------------------------------
# Details:  Exit the program on success. Called on program successfully done
#           its work. Returns a status result to the caller.
# Args:     vnResult    - (R) 0 or greater indicating success.
#           vMsg        - (R) Success message if any to show success to user.
# Returns:  None.
# Throws:   None.
#--
def program_exit_success( vnResult, vMsg ):
    strMsg = "";

    if vMsg.__len__() != 0:
        strMsg = "%s: %s (%d)" % (strExitMsgSuccess, vMsg, vnResult);
        print strMsg;

    sys.exit( vnResult );

#++---------------------------------------------------------------------------
# Details:  Exit the program with error. Called on exit program failed its
#           task. Returns a status result to the caller.
# Args:     vnResult    - (R) A negative number indicating error condition.
#           vMsg        - (R) Error message to show to user.
# Returns:  None.
# Throws:   None.
#--
def program_exit_on_failure( vnResult, vMsg ):
    print "%s%s (%d)" % (strExitMsgError, vMsg, vnResult);
    sys.exit( vnResult );

#++---------------------------------------------------------------------------
# Details:  Exit the program return a exit result number and print a message.
#           Positive numbers and zero are returned for success other error
#           occurred.
# Args:     vnResult    - (R) A -ve (an error), 0 or +ve number (ok or status).
#           vMsg        - (R) Error message to show to user.
# Returns:  None.
# Throws:   None.
#--
def program_exit( vnResult, vMsg ):
    if vnResult >= 0:
        program_exit_success( vnResult, vMsg );
    else:
        program_exit_on_failure( vnResult, vMsg );

#++---------------------------------------------------------------------------
# Details:  Dump input parameters.
# Args:     vDictArgs   - (R) Map of input args to value.
# Returns:  None.
# Throws:   None.
#--
def print_out_input_parameters( vDictArgs ):
    for arg, val in vDictArgs.iteritems():
        strEqs = "";
        strQ = "";
        if val.__len__() != 0:
            strEqs = " =";
            strQ = "\"";
        print "%s%s%s %s%s%s\n" % (strParameter, arg, strEqs, strQ, val, strQ);

#++---------------------------------------------------------------------------
# Details:  Locate the lldb.swig file. No checking for path correctness is
#           done here as assumed all values checked already. Path is adapted
#           to be compatible with the platform file system.
# Args:     vstrSrcRoot - (R) Directory path to the lldb source root.
#           veOSType    - (R) Current OS type enumeration.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_file_exists( vstrSrcRoot, veOSType ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_file_exists()" );
    bOk = True;
    strStatusMsg = "";
    strSwigFilePathName = "/scripts/lldb.swig";

    strFullPath = os.path.normcase( vstrSrcRoot + strSwigFilePathName );
    bOk = os.path.isfile( strFullPath );
    if bOk:
        if gbDbgFlag:
            print strSwigFileFound;
    else:
        strStatusMsg = strSwigFileFoundNotFound % strFullPath;

    return (bOk, strStatusMsg);

#++---------------------------------------------------------------------------
# Details:  Locate SWIG sub script language directory and the script within
#           and execute SWIG for that script language.
# Args:     vStrScriptLang      - (R) Name of the script language to build.
#           vSwigBuildFileName  - (R) Prefix file name to build full name.
#           vDictArgs           - (R) Program input parameters.
# Returns:  Int     - 0 = Success, < 0 some error condition.
#           Str     - Error message.
# Throws:   None.
#--
def run_swig( vStrScriptLang, vSwigBuildFileName, vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "run_swig()" );
    nResult = 0;
    strStatusMsg = "";
    strScriptFile = vSwigBuildFileName % vStrScriptLang;
    strScriptFileDir = "%s%s/%s" % (vDictArgs[ "--srcRoot" ], "/scripts",
                                    vStrScriptLang);
    strScriptFilePath = "%s/%s" % (strScriptFileDir, strScriptFile);

    # Check for the existence of the script file
    strPath = os.path.normcase( strScriptFilePath );
    bOk = os.path.exists( strPath );
    if bOk == False:
        strDir = os.path.normcase( strScriptFileDir );
        strStatusMsg = strSwigScriptNotFound % (strScriptFile, strDir);
        return (-9, strStatusMsg);

    if gbDbgFlag:
        print strSwigScriptLangFound % vStrScriptLang;
        print strSwigExecuteMsg % vStrScriptLang;

    # Change where Python looks for our modules
    strDir = os.path.normcase( strScriptFileDir );
    sys.path.append( strDir );

    # Execute the specific language script
    dictArgs = vDictArgs; # Remove any args not required before passing on
    strModuleName = strScriptFile[ : strScriptFile.__len__() - 3 ];
    module = __import__( strModuleName );
    nResult, strStatusMsg = module.main( dictArgs );

    # Revert sys path
    sys.path.remove( strDir );

    return (nResult, strStatusMsg);

#++---------------------------------------------------------------------------
# Details:  Step through each SWIG sub directory script language supported
#           type and execute SWIG to build wrapper code based on that language.
#           If an error occurs for a build this function will return with an
#           error and not continue with proceed script builds.
#           For each scripting language, make sure the build script for that
#           language exists.
#           For now the only language we support is Python, but we expect this
#           to change.
# Args:     vDictArgs   - (R) Program input parameters.
# Returns:  Int     - 0 = Success, < 0 some error condition.
#           Str     - Error message.
# Throws:   None.
#--
def run_swig_for_each_script_supported( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "run_swig_for_each_script_supported()" );
    nResult = 0;
    strStatusMsg = "";
    strSwigScriptDir = vDictArgs[ "--srcRoot" ] + "/scripts";
    strSwigBuildFileName = "buildSwig%s.py";

    # Check for the existence of the SWIG scripts folder
    strScriptsDir = os.path.normcase( strSwigScriptDir );
    bOk = os.path.exists( strScriptsDir );
    if bOk == False:
        return (-8, strSwigScriptDirNotFound);

    # Look for any script language directories to build for
    listDirs = [];
    nDepth = 1;
    for strPath, listDirs, listFiles in os.walk( strSwigScriptDir ):
        nDepth = nDepth - 1;
        if nDepth == 0:
            break;

    # Skip the directory that contains the interface files.
    listDirs.remove('interface')

    if gbDbgFlag:
        print strSwigScriptLangsFound,
        for dir in listDirs:
            print dir,
        print "\n";

    # Iterate script directory find any script language directories
    for scriptLang in listDirs:
        dbg.dump_text( "Executing language script for \'%s\'" % scriptLang );
        nResult, strStatusMsg = run_swig( scriptLang, strSwigBuildFileName,
                                          vDictArgs );
        if nResult < 0:
            break;

    if nResult < 0:
        strTmp = strSwigExecuteError % scriptLang;
        strTmp += strStatusMsg;
        strStatusMsg = strTmp;

    return (nResult, strStatusMsg);

#++---------------------------------------------------------------------------
# Details:  Dummy function - system unknown. Function should not be called.
# Args:     vDictArgs   - (R) Program input parameters.
# Returns:  Bool    - False = Program logic error.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists_Unknown( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists_Unknown()" );
    # Do nothing
    return (False, strMsgErrorOsTypeUnknown);

#++---------------------------------------------------------------------------
# Details:  Locate the SWIG executable file in a Windows system. Several hard
#           coded predetermined possible file path locations are searched.
#           (This is good candidate for a derived class object)
# Args:     vDictArgs   - (W) Program input parameters.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists_Windows( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists_Windows()" );

    # Will always be true as it assumed the path to SWIG executable will be
    # in the OS system environmental variable %PATH%. Easier this way as the
    # user may have renamed the directory and or custom path installation.
    bExeFileFound = True;
    vDictArgs[ "--swigExePath" ] = "";
    vDictArgs[ "--swigExeName" ] = "swig.exe";
    return (bExeFileFound, None);

#++---------------------------------------------------------------------------
# Details:  Locate the SWIG executable file in a Linux system. Several hard
#           coded predetermined possible file path locations are searched.
#           (This is good candidate for a derived class object)
# Args:     vDictArgs   - (W) Program input parameters.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists_Linux( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists_Linux()" );
    bExeFileFound = False;

    strSwigExe = "swig";
    strSwigExePath = "/usr/bin";
    strExe = os.path.normcase( "%s/%s" % (strSwigExePath, strSwigExe) );
    if os.path.isfile( strExe ) and os.access( strExe, os.X_OK ):
        bExeFileFound = True;
        vDictArgs[ "--swigExePath" ] = os.path.normcase( strSwigExePath );
        vDictArgs[ "--swigExeName" ] = strSwigExe;
        return (bExeFileFound, None);

    strSwigExePath = "/usr/local/bin";
    strExe = os.path.normcase( "%s/%s" % (strSwigExePath, strSwigExe) );
    if os.path.isfile( strExe ) and os.access( strExe, os.X_OK ):
        bExeFileFound = True;
        vDictArgs[ "--swigExePath" ] = os.path.normcase( strSwigExePath );
        vDictArgs[ "--swigExeName" ] = strSwigExe;
        return (bExeFileFound, None);

    return (bExeFileFound, strSwigExeFileNotFound);

#++---------------------------------------------------------------------------
# Details:  Locate the SWIG executable file in a OSX system. Several hard
#           coded predetermined possible file path locations are searched.
#           (This is good candidate for a derived class object)
# Args:     vDictArgs   - (W) Program input parameters.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists_Darwin( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists_Darwin()" );
    bExeFileFound = False;
    # ToDo: Find the SWIG executable and add the path to the args dictionary
    #vDictArgs.[ "--swigExePath" ] = "/usr/bin/swig";
    strStatusMsg = "Sorry function 'check_lldb_swig_executable_file_exists_Darwin()' is not implemented";

    return (bExeFileFound, strStatusMsg);

#++---------------------------------------------------------------------------
# Details:  Locate the SWIG executable file in a OSX system. Several hard
#           coded predetermined possible file path locations are searched.
#           (This is good candidate for a derived class object)
# Args:     vDictArgs   - (W) Program input parameters.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists_FreeBSD( vDictArgs ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists_FreeBSD()" );
    bExeFileFound = False;
    # ToDo: Find the SWIG executable and add the path to the args dictionary
    #vDictArgs.[ "--swigExePath" ] = "/usr/bin/swig";
    strStatusMsg = "Sorry function 'check_lldb_swig_executable_file_exists_FreeBSD()' is not implemented";

    return (bExeFileFound, strStatusMsg);

#++---------------------------------------------------------------------------
# Details:  Locate the SWIG executable file. Several hard coded predetermined
#           possible file path locations are searched.
# Args:     vDictArgs   - (RW) Program input parameters.
#           veOSType    - (R) Current OS type enumeration.
# Returns:  Bool    - True = Success.
#                   - False = Failure file not found.
#           Str     - Error message.
# Throws:   None.
#--
def check_lldb_swig_executable_file_exists( vDictArgs, veOSType ):
    dbg = utilsDebug.CDebugFnVerbose( "check_lldb_swig_executable_file_exists()" );
    bExeFileFound = False;
    strStatusMsg = "";
    if "--swigExecutable" in vDictArgs:
        vDictArgs["--swigExeName"] = os.path.basename(vDictArgs["--swigExecutable"])
        vDictArgs["--swigExePath"] = os.path.dirname(vDictArgs["--swigExecutable"])
        bExeFileFound = True
    else:
        from utilsOsType import EnumOsType;
        switch = { EnumOsType.Unknown : check_lldb_swig_executable_file_exists_Unknown,
               EnumOsType.Darwin : check_lldb_swig_executable_file_exists_Darwin,
               EnumOsType.FreeBSD : check_lldb_swig_executable_file_exists_FreeBSD,
               EnumOsType.Linux : check_lldb_swig_executable_file_exists_Linux,
               EnumOsType.Windows : check_lldb_swig_executable_file_exists_Windows }
        bExeFileFound, strStatusMsg = switch[ veOSType ]( vDictArgs );
    return (bExeFileFound, strStatusMsg);
#++---------------------------------------------------------------------------
# Details:  Validate the arguments passed to the program. This function exits
#           the program should error with the arguments be found.
# Args:     vArgv   - (R) List of arguments and values.
# Returns:  Int     - 0 = success, -ve = some failure.
#           Dict    - Map of arguments names to argument values
# Throws:   None.
#--
def validate_arguments( vArgv ):
    dbg = utilsDebug.CDebugFnVerbose( "validate_arguments()" );
    strMsg = "";
    dictArgs = {};
    nResult = 0;
    strListArgs = "hdmM"; # Format "hiox:" = -h -i -o -x <arg>
    listLongArgs = ["srcRoot=", "targetDir=", "cfgBldDir=", "prefix=",
            "swigExecutable=", "argsFile"];
    dictArgReq = {  "-h": "o",          # o = optional, m = mandatory
                    "-d": "o",
                    "-m": "o",
                    "-M": "o",
                    "--srcRoot": "m",
                    "--targetDir": "m",
                    "--swigExecutable" : "o",
                    "--cfgBldDir": "o",
                    "--prefix": "o",
                    "--argsFile": "o" };
    strHelpInfo = get_help_information();

    # Check for mandatory parameters
    nResult, dictArgs, strMsg = utilsArgsParse.parse( vArgv, strListArgs,
                                                      listLongArgs,
                                                      dictArgReq,
                                                      strHelpInfo );
    if nResult < 0:
        program_exit_on_failure( nResult, strMsg );

    # User input -h for help
    if nResult == 1:
        program_exit_success( 0, strMsg );

    return (nResult, dictArgs);

#++---------------------------------------------------------------------------
# Details:  Program's main() with arguments passed in from the command line.
#           Program either exits normally or with error from this function -
#           top most level function.
# Args:     vArgv   - (R) List of arguments and values.
# Returns:  None
# Throws:   None.
#--
def main( vArgv ):
    dbg = utilsDebug.CDebugFnVerbose( "main()" );
    bOk = False;
    dictArgs = {};
    nResult = 0;
    strMsg = "";

    # The validate arguments fn will exit the program if tests fail
    nResult, dictArgs = validate_arguments( vArgv );

    eOSType = utilsOsType.determine_os_type();
    if eOSType == utilsOsType.EnumOsType.Unknown:
        program_exit( -4, strMsgErrorOsTypeUnknown );

    global gbDbgFlag;
    gbDbgFlag = dictArgs.has_key( "-d" );
    if gbDbgFlag:
        print_out_input_parameters( dictArgs );

    # Check to see if we were called from the Makefile system. If we were, check
    # if the caller wants SWIG to generate a dependency file.
    # Not used in this program, but passed through to the language script file
    # called by this program
    global gbMakeFileFlag;
    global gbSwigGenDepFileFlag;
    gbMakeFileFlag = dictArgs.has_key( "-m" );
    gbSwigGenDepFileFlag = dictArgs.has_key( "-M" );

    bOk, strMsg = check_lldb_swig_file_exists( dictArgs[ "--srcRoot" ], eOSType );
    if bOk == False:
        program_exit( -3, strMsg );

    bOk, strMsg = check_lldb_swig_executable_file_exists( dictArgs, eOSType );
    if bOk == False:
        program_exit( -6, strMsg );

    nResult, strMsg = run_swig_for_each_script_supported( dictArgs );

    program_exit( nResult, strMsg );

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

#TAG_PROGRAM_HELP_INFO
""" Details: Program main entry point.

    --------------------------------------------------------------------------
    Args:   -h (optional)   Print help information on this program.
            -d (optional)   Determines whether or not this script
                            outputs additional information when running.
            -m (optional)   Specify called from Makefile system. If given locate
                            the LLDBWrapPython.cpp in --srcRoot/source folder
                            else in the --targetDir folder.
            -M (optional)   Specify want SWIG to generate a dependency file.
            --srcRoot=      The root of the lldb source tree.
            --targetDir=    Where the lldb framework/shared library gets put.
            --cfgBldDir=    Where the buildSwigPythonLLDB.py program will
            (optional)      put the lldb.py file it generated from running
                            SWIG.
            --prefix=       Is the root directory used to determine where
            (optional)      third-party modules for scripting languages should
                            be installed. Where non-Darwin systems want to put
                            the .py and .so files so that Python can find them
                            automatically. Python install directory.
            --argsFile=     The args are read from a file instead of the
                            command line. Other command line args are ignored.
    Usage:
            buildSwigWrapperClasses.py --srcRoot=ADirPath --targetDir=ADirPath
            --cfgBldDir=ADirPath --prefix=ADirPath --swigExecutable=ADirPath -m -d

    Results:    0 Success
                -1 Error - invalid parameters passed.
                -2 Error - incorrect number of mandatory parameters passed.
                -3 Error - unable to locate lldb.swig file.
                -4 Error - unable to determine OS type.
                -5 Error - program called by another Python script not allowed.
                -6 Error - unable to locate the swig executable file.
                -7 Error - SWIG script execution failed.
                -8 Error - unable to locate the SWIG scripts folder.
                -9 Error - unable to locate the SWIG language script file.
                -100+    - Error messages from the SWIG language script file.
                -200+    - 200 +- the SWIG exit result.
    --------------------------------------------------------------------------

"""

# Called using "__main__" when not imported i.e. from the command line
if __name__ == "__main__":
    utilsDebug.CDebugFnVerbose.bVerboseOn = gbDbgVerbose;
    dbg = utilsDebug.CDebugFnVerbose( "__main__" );
    main( sys.argv[ 1: ] );
else:
    program_exit( -5, strMsgErrorNoMain );
