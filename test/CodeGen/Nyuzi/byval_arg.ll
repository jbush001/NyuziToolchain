; RUN: llc %s -o - | FileCheck %s
;
; When a structure argument is passed by value, the caller
; will allocate space and copy data into it. @func1 is called
; with a byval struct arg. It in turn calls another function,
; passing the structure by value to it.
; NyuziTargetLowering::LowerCall perfoms the copy out
;

target triple = "nyuzi-elf-none"

; Make the struct big enough that a memcpy is required
%struct.foo = type { i32, i32, [256 x i8] }

declare void @func2(%struct.foo* byval)

define void @func1(%struct.foo* byval %f) {
  call void @func2(%struct.foo* byval %f)

  ; f parameter becomes src for memcpy call
  ; CHECK-DAG: move s1, s0

  ; locally allocated stack space is dest parameter for memcpy
  ; CHECK-DAG: lea [[SAVENV:s[0-9]+]], 48(sp)

  ; size of structure
  ; CHECK-DAG: move s2, 264

  ; Copy to local stack object
  ; CHECK: call memcpy

  ; Now restore the pointer to the new stack object
  ; CHECK: move s0, [[SAVENV]]

  ; And pass a pointer to func2
  ; CHECK: call func2

  ret void
}
