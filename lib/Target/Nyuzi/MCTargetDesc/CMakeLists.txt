add_llvm_library(LLVMNyuziDesc
  NyuziMCTargetDesc.cpp
  NyuziMCAsmInfo.cpp
  NyuziMCCodeEmitter.cpp
  NyuziAsmBackend.cpp
  NyuziELFObjectWriter.cpp
  )

add_dependencies(LLVMNyuziDesc NyuziCommonTableGen)
