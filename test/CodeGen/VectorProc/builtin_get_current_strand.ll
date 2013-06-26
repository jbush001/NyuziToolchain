; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; __builtin_vp_get_current_strand is an intrinsic. Make sure it turns into
; a control register move.

define i32 @test() #0 {
entry:
  %0 = call i32 @llvm.vectorproc.__builtin_vp_get_current_strand()
  ret i32 %0
}

declare i32 @llvm.vectorproc.__builtin_vp_get_current_strand() #1

; CHECK: s{{[0-9]+}} = cr0
