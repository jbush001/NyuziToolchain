; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

@foo = global i32 12, align 4
@bar = global i32 13, align 4

define void @test() #0 {
  %1 = load i32* @foo, align 4
  store i32 %1, i32* @bar, align 4
  ret void
}

; CHECK: s[[FOOPTR:[0-9]+]] = &foo
; CHECK: s[[FOOVAL:[0-9]+]] = mem_l[s[[FOOPTR]]]
; CHECK: s[[BARPTR:[0-9]+]] = &bar
; CHECK: mem_l[s[[BARPTR]]] = s[[FOOVAL]]
