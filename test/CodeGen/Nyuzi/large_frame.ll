; RUN: llc %s -o - | FileCheck %s
;
; If the frame is large enough, the prologue cannot do a subtract with
; an immediate instruction to decrement the stack pointer. Instead, it
; loads the frame size into a register with shifts/ors and uses that
; register result to decrement the stack pointer.
;

target triple = "nyuzi-elf-none"

declare void @dummy_func(i32*)

define void @large_frame() {
  %1 = alloca [2048 x i32], align 4

  ; Ensure we allocate enough space
  ; CHECK: move [[SIZEREG1:s[0-9+]]], -2
  ; CHECK: shl [[SIZEREG1]], [[SIZEREG1]], 13
  ; CHECK: or [[SIZEREG1]], [[SIZEREG1]], 8128
  ; CHECK: add_i sp, sp, [[SIZEREG1]]
  ; CHECK: .cfi_def_cfa_offset 8256

  %2 = getelementptr inbounds [2048 x i32], [2048 x i32]* %1, i32 0, i32 0
  call void @dummy_func(i32* %2)

  ; CHECK: call dummy_func

  ; CHECK: load_32 ra,

  ; Clean up stack
  ; CHECK: move [[SIZEREG2:s[0-9]+]], 1
  ; CHECK: shl [[SIZEREG2]], [[SIZEREG2]], 13
  ; CHECK: or [[SIZEREG2]], [[SIZEREG2]], 64
  ; CHECK: add_i sp, sp, [[SIZEREG2]]

  ret void
}
