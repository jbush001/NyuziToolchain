; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

; XXX for many of these tests, LLVM performs transforms that change to a different
; compare. For example, checking if a number is greater than or equal to 27 might
; be converted to greater than 26.

define i32 @cmpisgt(i32 %a, i32 %b) {  ; CHECK: cmpisgt:
  %cmp = icmp sgt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiugt(i32 %a, i32 %b) {  ; CHECK: cmpiugt:
  %cmp = icmp ugt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpisge(i32 %a, i32 %b) {  ; CHECK: cmpisge:
  %cmp = icmp sge i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiuge(i32 %a, i32 %b) {  ; CHECK: cmpiuge:
  %cmp = icmp uge i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpislt(i32 %a, i32 %b) {  ; CHECK: cmpislt:
  %cmp = icmp slt i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiult(i32 %a, i32 %b) {  ; CHECK: cmpiult:
  %cmp = icmp ult i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpisle(i32 %a, i32 %b) {  ; CHECK: cmpisle:
  %cmp = icmp sle i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpiule(i32 %a, i32 %b) {  ; CHECK: cmpiule:
  %cmp = icmp ule i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_u s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpieq(i32 %a, i32 %b) {  ; CHECK: cmpieq:
  %cmp = icmp eq i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpine(i32 %a, i32 %b) {  ; CHECK: cmpine:
  %cmp = icmp ne i32 %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_i s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

; Immediate forms

define i32 @cmpisgtI(i32 %a, i32 %b) {  ; CHECK: cmpisgtI:
  %cmp = icmp sgt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpiugtI(i32 %a, i32 %b) {  ; CHECK: cmpiugtI:
  %cmp = icmp ugt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpisgeI(i32 %a, i32 %b) {  ; CHECK: cmpisgeI:

  %cmp = icmp sge i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_i s{{[0-9]+}}, s0, 26

  ret i32 %ret
}

define i32 @cmpiugeI(i32 %a, i32 %b) {  ; CHECK: cmpiugeI:
  %cmp = icmp uge i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_u s{{[0-9]+}}, s0, 26

  ret i32 %ret
}

define i32 @cmpisltI(i32 %a, i32 %b) {  ; CHECK: cmpisltI:
  %cmp = icmp slt i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpiultI(i32 %a, i32 %b) {  ; CHECK: cmpiultI:
  %cmp = icmp ult i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpisleI(i32 %a, i32 %b) {  ; CHECK: cmpisleI:
  %cmp = icmp sle i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_i s{{[0-9]+}}, s0, 28

  ret i32 %ret
}

define i32 @cmpiuleI(i32 %a, i32 %b) {  ; CHECK: cmpiuleI:
  %cmp = icmp ule i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_u s{{[0-9]+}}, s0, 28

  ret i32 %ret
}

define i32 @cmpieqI(i32 %a, i32 %b) {  ; CHECK: cmpieqI:
  %cmp = icmp eq i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

define i32 @cmpineI(i32 %a, i32 %b) {  ; CHECK: cmpineI:
  %cmp = icmp ne i32 %a, 27
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_i s{{[0-9]+}}, s0, 27

  ret i32 %ret
}

; Floating point

define i32 @cmpfgt(float %a, float %b) {  ; CHECK: cmpfgt:
  %cmp = fcmp ogt float %a, %b      ; CHECK: cmpgt_f s{{[0-9]+}}, s0, s1
  %ret = zext i1 %cmp to i32
  ret i32 %ret
}

define i32 @cmpfge(float %a, float %b) {  ; CHECK: cmpfge:
  %cmp = fcmp oge float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpflt(float %a, float %b) {  ; CHECK: cmpflt:
  %cmp = fcmp olt float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfle(float %a, float %b) {  ; CHECK: cmpfle:
  %cmp = fcmp ole float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfeq(float %a, float %b) {  ; CHECK: cmpfeq:
  %cmp = fcmp oeq float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfne(float %a, float %b) {  ; CHECK: cmpfne:
  %cmp = fcmp one float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_f s{{[0-9]+}}, s0, s1

  ret i32 %ret
}

define i32 @cmpfgtu(float %a, float %b) {  ; CHECK: cmpfgtu:
  %cmp = fcmp ugt float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmple_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfgeu(float %a, float %b) {  ; CHECK: cmpfgeu:
  %cmp = fcmp uge float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmplt_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfltu(float %a, float %b) {  ; CHECK: cmpfltu:
  %cmp = fcmp ult float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpge_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfleu(float %a, float %b) {  ; CHECK: cmpfleu:
  %cmp = fcmp ule float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpgt_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfequ(float %a, float %b) {  ; CHECK: cmpfequ:
  %cmp = fcmp ueq float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpne_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @cmpfneu(float %a, float %b) {  ; CHECK: cmpfneu:
  %cmp = fcmp une float %a, %b
  %ret = zext i1 %cmp to i32

  ; CHECK: cmpeq_f [[CMPRES:s[0-9]+]], s0, s1
  ; CHECK: xor s{{[0-9]+}}, [[CMPRES]]

  ret i32 %ret
}

define i32 @check_notnan(float %a) {  ; CHECK: check_notnan:
  %lnot = fcmp ord float %a, 0.000000e+00
  %lnot.ext = zext i1 %lnot to i32

  ; CHECK: cmpeq_f

  ret i32 %lnot.ext
}

define i32 @check_nan(float %a) {  ; CHECK: check_nan:
  %lnot = fcmp uno float %a, 0.000000e+00
  %lnot.ext = zext i1 %lnot to i32

  ; CHECK: cmpeq_f

  ret i32 %lnot.ext
}
