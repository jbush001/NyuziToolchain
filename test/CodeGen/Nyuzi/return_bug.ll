; RUN: llc %s -o - | FileCheck %s
;
; Regression test
; The original bug was that call was treated as a terminator and thus
; considered part of the return sequence.  The callee-saved registers
; would end up getting restored before the call instead of after it.
;

target triple = "nyuzi-elf-none"

@foo = global i32 12, align 4

define void @_Z9printCharc(i32 %c) {
  ret void
}

define void @_Z8printHexj(i32 %value) {
  call void @_Z9printCharc(i32 %value)	; Need to dirty ra pointer
  store i32 %value, i32* @foo, align 4	; Add a non-terminator instruction
  call void @_Z9printCharc(i32 10)	; This one should not be part of epilogue
  ret void

  ; CHECK: move s{{[0-9]+}}, 10
  ; CHECK: call _Z9printCharc
  ; CHECK: load_32 ra, {{[0-9]+}}(sp)

}
