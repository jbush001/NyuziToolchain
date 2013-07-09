; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

; These are emitted into the constant pool
; CHECK: [[FOO_LBL:[0-9A-Za-z_]+]]: 
; CHECK: .word foo
; CHECK: [[BAR_LBL:[0-9A-Za-z_]+]]: 
; CHECK: .word bar

define void @test() #0 {
  %1 = load i32* @foo, align 4

; CHECK: s[[FOO_REG:[0-9]+]] = mem_l{{[\[]}}[[FOO_LBL]]
; CHECK: = mem_l[s[[FOO_REG]]]

  store i32 %1, i32* @bar, align 4

; CHECK: s[[BAR_REG:[0-9]+]] = mem_l{{[\[]}}[[BAR_LBL]]
; CHECK: mem_l[s[[BAR_REG]]] =

  ret void
}
