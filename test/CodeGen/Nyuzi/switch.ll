; RUN: llc %s -o - | FileCheck %s
;
; Test switch instruction
;

target triple = "nyuzi-elf-none"

; Test creating a jump table

define i32 @foo(i32 %i, i32 %j) {
entry:
  switch i32 %i, label %return [
    i32 0, label %sw.bb
    i32 1, label %sw.bb1
    i32 2, label %sw.bb2
    i32 3, label %sw.bb4
  ]

  ; CHECK-DAG: movehi [[A:s[0-9]+]], hi(.LJTI0_0)
  ; CHECK-DAG: or [[B:s[0-9]+]], [[A]], lo(.LJTI0_0)
  ; CHECK-DAG: shl [[D:s[0-9]+]], s0, 2
  ; CHECK-DAG: add_i [[E:s[0-9]+]], [[D]], [[B]]
  ; CHECK: load_32 [[C:s[0-9]+]], ([[E]])
  ; CHECK: b [[C]]

sw.bb:
  %add = add nsw i32 %j, 1
  br label %return

sw.bb1:
  %mul = mul nsw i32 %j, 7
  br label %return

sw.bb2:
  %mul3 = mul nsw i32 %j, %j
  br label %return

sw.bb4:
  %sub = add nsw i32 %j, -1
  %shl = shl i32 %j, %sub
  br label %return

return:
  %retval.0 = phi i32 [ %shl, %sw.bb4 ], [ %mul3, %sw.bb2 ], [ %mul, %sw.bb1 ], [ %add, %sw.bb ], [ %j, %entry ]
  ret i32 %retval.0
}

; CHECK: .LJTI0_0:
; CHECK: .long .LBB0_2
; CHECK: .long .LBB0_3
; CHECK: .long .LBB0_4
; CHECK: .long .LBB0_5

