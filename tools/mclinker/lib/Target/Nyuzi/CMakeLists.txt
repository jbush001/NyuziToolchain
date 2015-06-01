add_llvm_library(MCLDNyuziLDBackend
  NyuziDiagnostic.cpp
  NyuziELFDynamic.cpp
  NyuziEmulation.cpp
  NyuziLDBackend.cpp
  NyuziRelocator.cpp
  LINK_LIBS
    MCLDNyuziTargetInfo
    MCLDCore
    MCLDFragment
    MCLDObject
    MCLDTarget
  )

add_subdirectory(TargetInfo)
