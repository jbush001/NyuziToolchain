#include "NyuziTargetTransformInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"
using namespace llvm;

unsigned NyuziTTIImpl::getNumberOfRegisters(bool Vec) const {
  return 32;
}

unsigned NyuziTTIImpl::getRegisterBitWidth(bool Vector) const {
  if (Vector)
    return 512;
  else
    return 32;
}

unsigned NyuziTTIImpl::getMinVectorRegisterBitWidth() const {
  return 512;
}

bool NyuziTTIImpl::shouldMaximizeVectorBandwidth(bool OptSize) const {
  return false;
}

unsigned NyuziTTIImpl::getMaxInterleaveFactor(unsigned VF) const {
  return 32;
}

bool NyuziTTIImpl::hasBranchDivergence() const {
  return false;
}
