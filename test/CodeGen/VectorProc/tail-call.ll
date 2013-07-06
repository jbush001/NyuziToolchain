; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @doSomethingElse(i32 %a, i32 %b) #0 {
entry:
  %result = tail call i32 @doSomething(i32 %a, i32 %b) #2

  ; CHECK: call

  ret i32 %result
}

declare i32 @doSomething(i32, i32) #1
