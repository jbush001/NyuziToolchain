; RUN: llc %s -o - | FileCheck %s
;
; Scalar only comparison tests
; These tests are not included in operator_tests because LLVM performs transforms
; that change to a different compare:
; - In some cases, LLVM does this for integer comparisions. For example, checking
;   if a number is greater than or equal to 27 might be converted to greater
;   than 26.
; - We do this explicitly to support unordered floating point comparisions.
;   Hardware comparisons are ordered (if either component is NaN, the comparison
;   is false). For unordered comparisons, pick the opposite comparision and XOR
;   the result with 0xffff to invert it.
;

target triple = "nyuzi-elf-none"

define i32 @cmpisgt(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisgt:
  %cmp = icmp sgt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiugt(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiugt:
  %cmp = icmp ugt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpisge(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisge:
  %cmp = icmp sge i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiuge(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiuge:
  %cmp = icmp uge i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpislt(i32 %a, i32 %b) { ; CHECK-LABEL: cmpislt:
  %cmp = icmp slt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiult(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiult:
  %cmp = icmp ult i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpisle(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisle:
  %cmp = icmp sle i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiule(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiule:
  %cmp = icmp ule i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpieq(i32 %a, i32 %b) { ; CHECK-LABEL: cmpieq:
  %cmp = icmp eq i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpine(i32 %a, i32 %b) { ; CHECK-LABEL: cmpine:
  %cmp = icmp ne i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

; Immediate forms

define i32 @cmpisgtI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisgtI:
  %cmp = icmp sgt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpiugtI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiugtI:
  %cmp = icmp ugt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpisgeI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisgeI:

  %cmp = icmp sge i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, 26

  ret i32 %ret
}

define i32 @cmpiugeI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiugeI:
  %cmp = icmp uge i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, 26

  ret i32 %ret
}

define i32 @cmpisltI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisltI:
  %cmp = icmp slt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpiultI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiultI:
  %cmp = icmp ult i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpisleI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpisleI:
  %cmp = icmp sle i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, 28

  ret i32 %ret
}

define i32 @cmpiuleI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpiuleI:
  %cmp = icmp ule i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, 28

  ret i32 %ret
}

define i32 @cmpieqI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpieqI:
  %cmp = icmp eq i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpineI(i32 %a, i32 %b) { ; CHECK-LABEL: cmpineI:
  %cmp = icmp ne i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

; Floating point

define i32 @cmpfgt(float %a, float %b) { ; CHECK-LABEL: cmpfgt:
  %cmp = fcmp ogt float %a, %b      ; CHECK: cmpgt_f s{{[0-9]+}}, s0, s1
  %ret = zext i1 %cmp to i32
  ret i32 %ret
}

define i32 @cmpfge(float %a, float %b) { ; CHECK-LABEL: cmpfge:
  %cmp = fcmp oge float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpflt(float %a, float %b) { ; CHECK-LABEL: cmpflt:
  %cmp = fcmp olt float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfle(float %a, float %b) { ; CHECK-LABEL: cmpfle:
  %cmp = fcmp ole float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfeq(float %a, float %b) { ; CHECK-LABEL: cmpfeq:
  %cmp = fcmp oeq float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfne(float %a, float %b) { ; CHECK-LABEL: cmpfne:
  %cmp = fcmp one float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfgtu(float %a, float %b) { ; CHECK-LABEL: cmpfgtu:
  %cmp = fcmp ugt float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfgeu(float %a, float %b) { ; CHECK-LABEL: cmpfgeu:
  %cmp = fcmp uge float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfltu(float %a, float %b) { ; CHECK-LABEL: cmpfltu:
  %cmp = fcmp ult float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfleu(float %a, float %b) { ; CHECK-LABEL: cmpfleu:
  %cmp = fcmp ule float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfequ(float %a, float %b) { ; CHECK-LABEL: cmpfequ:
  %cmp = fcmp ueq float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfneu(float %a, float %b) { ; CHECK-LABEL: cmpfneu:
  %cmp = fcmp une float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @check_notnan(float %a) { ; CHECK-LABEL: check_notnan:
  %lnot = fcmp ord float %a, 0.000000e+00
  %lnot.ext = zext i1 %lnot to i32

  ; CHECK: cmpeq_f

  ret i32 %lnot.ext
}

define i32 @check_nan(float %a) { ; CHECK-LABEL: check_nan:
  %lnot = fcmp uno float %a, 0.000000e+00
  %lnot.ext = zext i1 %lnot to i32

  ; CHECK: cmpeq_f

  ret i32 %lnot.ext
}
