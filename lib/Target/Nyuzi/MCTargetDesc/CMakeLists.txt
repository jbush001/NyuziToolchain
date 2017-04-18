add_llvm_library(LLVMNyuziDesc
  NyuziMCTargetDesc.cpp
  NyuziMCAsmInfo.cpp
  NyuziMCCodeEmitter.cpp
  NyuziAsmBackend.cpp
  NyuziELFObjectWriter.cpp
  NyuziMCExpr.cpp
  )

add_dependencies(LLVMNyuziDesc NyuziCommonTableGen)
