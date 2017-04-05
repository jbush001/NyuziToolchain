; RUN: llc %s -o - | FileCheck %s
;
; Directly branching on a fcmp negates the 16 lower bits of the comparison
; result before branching. This is doubly bad because the constant for that
; negation (0xffff) doesn't fit into an immediate.
; Instead, it should just generate a compare followed by a conditional branch.
;
; For now this test just records this inefficency.
; XFAIL: *

target triple = "nyuzi-elf-none"

define i1 @branch_on_fcmp(float %a) {
entry:

  ; CHECK: cmpgt_f [[CMP_RESULT:s[0-9]+]], s0, s1
  ; CHECK-NEXT: b{{z|nz}} [[CMP_RESULT]]
  %positive = fcmp ogt float %a, 0.000000e+00
  br i1 %positive, label %return-true, label %return-false

return-true:
  ret i1 true

return-false:
  ret i1 false
}
