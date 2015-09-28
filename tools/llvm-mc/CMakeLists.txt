set(LLVM_LINK_COMPONENTS
  AllTargetsAsmPrinters
  AllTargetsAsmParsers
  AllTargetsDescs
  AllTargetsDisassemblers
  AllTargetsInfos
  MCDisassembler
  MC
  MCParser
  Support
  )

add_llvm_tool(llvm-mc
  llvm-mc.cpp
  Disassembler.cpp
  )
