//===- NyuziMCExpr.h - Nyuzi specific MC expression classes -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NYUZI_MCTARGETDESC_NYUZIMCEXPR_H
#define LLVM_LIB_TARGET_NYUZI_MCTARGETDESC_NYUZIMCEXPR_H

#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCValue.h"

namespace llvm {

class NyuziMCExpr : public MCTargetExpr {
public:
  enum VariantKind {
    VK_Nyuzi_NONE,
    VK_Nyuzi_ABS_HI,
    VK_Nyuzi_ABS_LO,
    VK_Nyuzi_GOT
  };

  static const NyuziMCExpr *create(VariantKind Kind, const MCExpr *Expr,
                                   MCContext &Ctx);
  VariantKind getKind() const { return Kind; }
  const MCExpr *getSubExpr() const { return Expr; }
  void printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool evaluateAsRelocatableImpl(MCValue &Res, const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override;
  void visitUsedExpr(MCStreamer &Streamer) const override;
  MCFragment *findAssociatedFragment() const override {
    return getSubExpr()->findAssociatedFragment();
  }

  void fixELFSymbolsInTLSFixups(MCAssembler & /*Asm*/) const override {}

  static bool classof(const MCExpr *E) {
    return E->getKind() == MCExpr::Target;
  }

private:
  const VariantKind Kind;
  const MCExpr *Expr;

  explicit NyuziMCExpr(VariantKind Kind, const MCExpr *Expr)
     : Kind(Kind), Expr(Expr) {}
};

} // end namespace llvm

#endif
