#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"
#include "NyuziTargetMachine.h"

namespace llvm {
class NyuziTTIImpl final : public BasicTTIImplBase<NyuziTTIImpl> {
  typedef BasicTTIImplBase<NyuziTTIImpl> BaseT;
  typedef TargetTransformInfo TTI;
  friend BaseT;

  const NyuziSubtarget *ST;
  const NyuziTargetLowering *TLI;

  const NyuziSubtarget *getST() const { return ST; }
  const NyuziTargetLowering *getTLI() const { return TLI; }

public:
  explicit NyuziTTIImpl(const NyuziTargetMachine *TM, const Function &F)
    : BaseT(TM, F.getParent()->getDataLayout()),
      ST(TM->getSubtargetImpl(F)),
      TLI(ST->getTargetLowering()) {}

  unsigned getNumberOfRegisters(bool Vector) const;
  unsigned getRegisterBitWidth(bool Vector) const;
  unsigned getMinVectorRegisterBitWidth() const;
  bool shouldMaximizeVectorBandwidth(bool OptSize) const;
  unsigned getMaxInterleaveFactor(unsigned VF) const;
  bool hasBranchDivergence() const;
};
}
