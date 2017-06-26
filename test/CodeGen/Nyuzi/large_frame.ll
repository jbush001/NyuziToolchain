; RUN: llc %s -o - | FileCheck %s
;
; If the frame is large enough, the prologue cannot do a subtract with
; an immediate instruction to decrement the stack pointer. Instead, it
; loads the frame size into a register with shifts/ors and uses that
; register result to decrement the stack pointer.
;

target triple = "nyuzi-elf-none"

declare void @dummy_func(i32*)

define i32 @large_frame() {
  %1 = alloca i32, align 4
  %2 = alloca [2048 x i32], align 4

  ; Ensure we allocate enough space
  ; CHECK: movehi [[SIZEREG1:s[0-9+]]], 524286
  ; CHECK: or [[SIZEREG1]], [[SIZEREG1]], 8128
  ; CHECK: add_i sp, sp, [[SIZEREG1]]
  ; CHECK: .cfi_def_cfa_offset 8256

  ; Access the large array so it doesn't get optimized away
  %3 = getelementptr inbounds [2048 x i32], [2048 x i32]* %2, i32 0, i32 0
  call void @dummy_func(i32* %3)
  ; CHECK: call dummy_func

  ; Access a pointer with a large offset
  %retval = load i32, i32* %1
  ; CHECK: movehi [[PTRREG:s[0-9+]]], 1
  ; CHECK: add_i [[PTRREG]], sp, [[PTRREG]]
  ; CHECK: load_32 {{s[0-9]+}}, 56([[PTRREG]])

  ; CHECK: load_32 ra,

  ; Make sure stack is cleaned up correctly
  ; CHECK: movehi [[SIZEREG2:s[0-9]+]], 1
  ; CHECK: or [[SIZEREG2]], [[SIZEREG2]], 64
  ; CHECK: add_i sp, sp, [[SIZEREG2]]

  ret i32 %retval
}
