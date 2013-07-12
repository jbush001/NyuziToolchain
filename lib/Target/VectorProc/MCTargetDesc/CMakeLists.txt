add_llvm_library(LLVMVectorProcDesc
  VectorProcMCTargetDesc.cpp
  VectorProcMCAsmInfo.cpp
  VectorProcMCCodeEmitter.cpp
  VectorProcAsmBackend.cpp
  VectorProcELFObjectWriter.cpp
  )

add_dependencies(LLVMVectorProcDesc VectorProcCommonTableGen)
