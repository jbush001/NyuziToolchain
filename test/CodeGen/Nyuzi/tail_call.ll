; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

define i32 @doSomethingElse(i32 %a, i32 %b) {
  %result = tail call i32 @doSomething(i32 %a, i32 %b)

  ; CHECK: call

  ret i32 %result
}

declare i32 @doSomething(i32, i32)
