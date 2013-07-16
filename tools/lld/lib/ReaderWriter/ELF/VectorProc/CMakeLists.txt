add_lld_library(lldVectorProcELFTarget
  VectorProcTargetHandler.cpp
  VectorProcTargetInfo.cpp
  )

target_link_libraries(lldVectorProcELFTarget
  lldCore
  )
