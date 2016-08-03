; RUN: llc %s -o - | FileCheck %s
;
; Calling alloca with a variable amount will adjust stack pointer
;

target triple = "nyuzi-elf-none"

declare void @callee(i8* %arg);

define void @dynamic_stackalloc(i32 %size) {

  ; With dynamic stack allocations, need to use a frame pointer
  ; CHECK: move fp, sp

  %ptr = alloca i8, i32 %size, align 1
  call void @callee(i8* %ptr);

  ; This aligns the size to a 64 byte size
  ; CHECK: add_i s0, s0, 63
  ; CHECK: and s0, s0, -64

  ; Decrement stack pointer
  ; CHECK: sub_i s0, sp, s0

  ; Pass argument to callee
  ; CHECK: move sp, s0
  ; CHECK: call callee

  ret void
}

