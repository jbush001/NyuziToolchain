; RUN: llc %s -o - | FileCheck %s -check-prefix=CHECK-STATIC
; RUN: llc -relocation-model=pic %s -o - | FileCheck %s -check-prefix=CHECK-PIC
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

  ; CHECK-STATIC-DAG: movehi [[A:s[0-9]+]], hi(.LJTI0_0)
  ; CHECK-STATIC-DAG: or [[B:s[0-9]+]], [[A]], lo(.LJTI0_0)
  ; CHECK-STATIC-DAG: shl [[D:s[0-9]+]], s{{[0-9+]}}, 2
  ; CHECK-STATIC-DAG: add_i [[E:s[0-9]+]], [[D]], [[B]]
  ; CHECK-STATIC: load_32 [[C:s[0-9]+]], ([[E]])
  ; CHECK-STATIC: b [[C]]

	; CHECK-PIC-DAG: load_32 [[A:s[0-9]+]], got(.LJTI0_0)(gp)
	; CHECK-PIC-DAG: shl [[B:s[0-9]+]], s{{[0-9+]}}, 2
	; CHECK-PIC-DAG: add_i [[C:s[0-9]+]], [[B]], [[A]]
	; CHECK-PIC-DAG: load_32 [[C:s[0-9]+]], ([[C]])
	; CHECK-PIC: add_i [[D:s[0-9]+]], [[C]], [[A]]
	; CHECK-PIC: b [[D]]

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

; CHECK-STATIC: .LJTI0_0:
; CHECK-STATIC: .long .LBB0_2
; CHECK-STATIC: .long .LBB0_3
; CHECK-STATIC: .long .LBB0_4
; CHECK-STATIC: .long .LBB0_5

; Ensure these are emitted in the text section
; CHECK-PIC-NOT: .rodata
; CHECK-PIC: .LJTI0_0:
; CHECK-PIC: .long	.LBB0_2-.LJTI0_0
; CHECK-PIC: .long	.LBB0_3-.LJTI0_0
; CHECK-PIC: .long	.LBB0_4-.LJTI0_0
; CHECK-PIC: .long	.LBB0_5-.LJTI0_0
