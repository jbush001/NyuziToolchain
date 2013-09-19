set(LLVM_TARGET_DEFINITIONS VectorProc.td)

tablegen(LLVM VectorProcGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM VectorProcGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM VectorProcGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM VectorProcGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM VectorProcGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM VectorProcGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM VectorProcGenCallingConv.inc -gen-callingconv)
tablegen(LLVM VectorProcGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM VectorProcGenMCCodeEmitter.inc -gen-emitter -mc-emitter)
tablegen(LLVM VectorProcGenDisassemblerTables.inc -gen-disassembler)
add_public_tablegen_target(VectorProcCommonTableGen)

add_llvm_target(VectorProcCodeGen
  VectorProcAsmPrinter.cpp
  VectorProcInstrInfo.cpp
  VectorProcISelDAGToDAG.cpp
  VectorProcISelLowering.cpp
  VectorProcFrameLowering.cpp
  VectorProcMachineFunctionInfo.cpp
  VectorProcRegisterInfo.cpp
  VectorProcSubtarget.cpp
  VectorProcTargetMachine.cpp
  VectorProcSelectionDAGInfo.cpp
  VectorProcMCInstLower.cpp
  VectorProcTargetObjectFile.cpp
  )

add_dependencies(LLVMVectorProcCodeGen intrinsics_gen)

add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(AsmParser)
add_subdirectory(InstPrinter)
add_subdirectory(Disassembler)

