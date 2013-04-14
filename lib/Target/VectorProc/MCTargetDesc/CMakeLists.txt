add_llvm_library(LLVMVectorProcDesc
  VectorProcMCTargetDesc.cpp
  VectorProcMCAsmInfo.cpp
  )

add_dependencies(LLVMVectorProcDesc VectorProcCommonTableGen)
