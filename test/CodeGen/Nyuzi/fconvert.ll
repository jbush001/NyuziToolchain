; Floating point conversion 
; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

@i = common global i32 0, align 4

define void @test() #0 {
entry:
  %0 = load i32, i32* @i, align 4
  %conv1 = sitofp i32 %0 to float
  %conv2 = fptosi float %conv1 to i32
  store i32 %conv2, i32* @i, align 4
  ret void
}

; CHECK: itof [[DEST1:s[0-9]+]], s{{[0-9]}}
; CHECK: ftoi s{{[0-9]+}}, [[DEST1]]

; XXX do this with vectors too...
