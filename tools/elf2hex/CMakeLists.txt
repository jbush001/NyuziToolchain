set(LLVM_LINK_COMPONENTS ${LLVM_TARGETS_TO_BUILD})

add_llvm_tool(elf2hex
  elf2hex.cpp
  )
