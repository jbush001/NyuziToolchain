; RUN: llc %s -o - | FileCheck %s
;
; Test sext, zext from v16i1 to i32 and truncate from i32 to v16i1
;

target triple = "nyuzi-elf-none"

define <16 x i32> @sext(<16 x i32>, <16 x i32>) { ; CHECK-LABEL: sext:
entry:
  %cmp = icmp uge <16 x i32> %0, %1
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpge_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @zext(<16 x i32>, <16 x i32>) { ; CHECK-LABEL: zext:
entry:
  %cmp = icmp uge <16 x i32> %0, %1
  %zext = zext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpge_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, 1

  ret <16 x i32> %zext
}

define <16 x i1> @trunc(<16 x i32>) { ; CHECK-LABEL: trunc:
entry:
  %trunc = trunc <16 x i32> %0 to <16 x i1>

  ; CHECK: and v0, v0, 1
  ; CHECK: cmpeq_i s0, v0, 1

  ret <16 x i1> %trunc
}
