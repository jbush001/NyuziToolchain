; Floating point conversion 
; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

@i = common global i32 0, align 4

define void @test() #0 {
entry:
  %0 = load i32* @i, align 4
  %conv1 = sitofp i32 %0 to float
  %conv2 = fptosi float %conv1 to i32
  store i32 %conv2, i32* @i, align 4
  ret void
}

; CHECK: f[[DEST1:[0-9]+]] = itof(s{{[0-9]}})
; CHECK: s{{[0-9]+}} = ftoi(f[[DEST1]])
