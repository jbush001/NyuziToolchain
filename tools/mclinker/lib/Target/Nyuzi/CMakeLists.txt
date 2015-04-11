add_mcld_library(MCLDNyuziLDBackend
  NyuziDiagnostic.cpp
  NyuziELFDynamic.cpp
  NyuziEmulation.cpp
  NyuziLDBackend.cpp
  NyuziRelocator.cpp
  )

add_subdirectory(TargetInfo)

target_link_libraries(MCLDNyuziLDBackend PRIVATE
  MCLDNyuziTargetInfo
  MCLDCore
  MCLDFragment
  MCLDObject
  MCLDTarget
  )
