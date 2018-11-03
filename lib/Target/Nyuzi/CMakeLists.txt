set(LLVM_TARGET_DEFINITIONS Nyuzi.td)

tablegen(LLVM NyuziGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM NyuziGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM NyuziGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM NyuziGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM NyuziGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM NyuziGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM NyuziGenCallingConv.inc -gen-callingconv)
tablegen(LLVM NyuziGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM NyuziGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM NyuziGenDisassemblerTables.inc -gen-disassembler)
add_public_tablegen_target(NyuziCommonTableGen)

add_llvm_target(NyuziCodeGen
  NyuziAsmPrinter.cpp
  NyuziInstrInfo.cpp
  NyuziISelDAGToDAG.cpp
  NyuziISelLowering.cpp
  NyuziFrameLowering.cpp
  NyuziMachineFunctionInfo.cpp
  NyuziRegisterInfo.cpp
  NyuziSubtarget.cpp
  NyuziTargetMachine.cpp
  NyuziMCInstLower.cpp
  NyuziTargetObjectFile.cpp
  NyuziTargetTransformInfo.cpp
  )

add_dependencies(LLVMNyuziCodeGen intrinsics_gen)

add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(AsmParser)
add_subdirectory(InstPrinter)
add_subdirectory(Disassembler)

