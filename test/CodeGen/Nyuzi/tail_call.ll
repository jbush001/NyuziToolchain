; RUN: llc %s -o - | FileCheck %s
;
; Tail calls are not supported on this architecture: they are converted to normal
; calls. Ensure the backend doesn't assert when it encounters one.
;

target triple = "nyuzi-elf-none"

declare i32 @doSomething(i32, i32)

define i32 @doSomethingElse(i32 %a, i32 %b) {
  %result = tail call i32 @doSomething(i32 %a, i32 %b)

  ; CHECK: call doSomething

  ret i32 %result
}
