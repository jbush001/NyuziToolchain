set(LLVM_NO_RTTI 1)

add_lldb_library(lldbPluginABINyuzi PLUGIN
  ABINyuzi.cpp

  LINK_LIBS
    lldbCore
    lldbSymbol
    lldbTarget
  LINK_COMPONENTS
    Support
  )