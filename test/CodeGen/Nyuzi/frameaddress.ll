; RUN: llc %s -o - | FileCheck %s
;
; Test that __builtin_frameaddress works properly
;

target triple = "nyuzi-elf-none"

declare i8* @llvm.frameaddress(i32) nounwind readnone

define i8* @f() {
  %1 = call i8* @llvm.frameaddress(i32 0)
  ret i8* %1

  ; CHECK: .cfi_startproc
  ; CHECK: .cfi_def_cfa_offset 64
  ; CHECK: .cfi_offset fp, -4
  ; CHECK:  move fp, sp
  ; CHECK: cfi_def_cfa_register fp
  ; CHECK: move s0, fp
  ; CHECK: .cfi_endproc
}
