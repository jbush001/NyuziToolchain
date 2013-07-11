add_llvm_library(LLVMVectorProcDesc
  VectorProcMCTargetDesc.cpp
  VectorProcMCAsmInfo.cpp
  VectorProcMCCodeEmitter.cpp
  )

add_dependencies(LLVMVectorProcDesc VectorProcCommonTableGen)
