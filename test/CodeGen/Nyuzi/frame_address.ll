; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

; Built-in frameaddress
declare i8* @llvm.frameaddress(i32) nounwind readnone

define i8* @f() nounwind uwtable {
entry:
  %0 = call i8* @llvm.frameaddress(i32 0)
  ret i8* %0

; CHECK: .cfi_startproc
; CHECK: .cfi_def_cfa_offset 64
; CHECK: .cfi_offset fp, -4
; CHECK:  move fp, sp
; CHECK: cfi_def_cfa_register fp
; CHECK: move s0, fp
; CHECK: .cfi_endproc
}

