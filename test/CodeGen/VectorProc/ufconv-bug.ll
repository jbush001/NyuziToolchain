; Code gen bug
; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define float @convert(i32 %value) #0 {
entry:
  %conv = uitofp i32 %value to float
  ret float %conv
}

; CHECK-NOT: add.i s1, pc, LCPI0_0