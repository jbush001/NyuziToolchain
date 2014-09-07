add_mcld_library(MCLDVectorProcLDBackend
  VectorProcDiagnostic.cpp
  VectorProcELFDynamic.cpp
  VectorProcEmulation.cpp
  VectorProcLDBackend.cpp
  VectorProcRelocator.cpp
  )

add_subdirectory(TargetInfo)

target_link_libraries(MCLDVectorProcLDBackend ${cmake_2_8_12_PRIVATE}
  MCLDVectorProcTargetInfo
  MCLDCore
  MCLDFragment
  MCLDObject
  MCLDTarget
  )
