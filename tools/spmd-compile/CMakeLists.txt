set(LLVM_LINK_COMPONENTS
  ${LLVM_TARGETS_TO_BUILD}
  AsmPrinter
  CodeGen
  Core
  MC
  ScalarOpts
  SelectionDAG
  Support
  Target
  )

add_llvm_tool(spmd-compile
  main.cpp
  SPMDBuilder.cpp
  AstNode.cpp
)
