add_lld_library(lldVectorProcELFTarget
  VectorProcTargetHandler.cpp
  VectorProcLinkingContext.cpp
  )

target_link_libraries(lldVectorProcELFTarget
  lldCore
  )
