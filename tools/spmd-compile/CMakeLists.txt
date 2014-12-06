find_package(BISON)
find_package(FLEX)
BISON_TARGET(PARSER Parser.yy ${CMAKE_CURRENT_BINARY_DIR}/Parser.cpp)
FLEX_TARGET(LEXER Scanner.ll ${CMAKE_CURRENT_BINARY_DIR}/Scanner.cpp)
ADD_FLEX_BISON_DEPENDENCY(LEXER PARSER)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

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
  ${BISON_PARSER_OUTPUTS}
  ${FLEX_LEXER_OUTPUTS}
)
