add_mcld_library(MCLDObject
  ObjectBuilder.cpp
  ObjectLinker.cpp
  SectionMap.cpp
  )

target_link_libraries(MCLDObject PRIVATE
  MCLDFragment
  MCLDLD
  MCLDScript
  )
