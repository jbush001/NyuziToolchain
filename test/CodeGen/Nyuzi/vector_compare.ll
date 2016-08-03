; RUN: llc %s -o - | FileCheck %s
;
; The native vector compare instructions return a bitmask, but the C operators
; return another vector. Ensure the backend properly expands the former to the latter.
;

target triple = "nyuzi-elf-none"

define <16 x i32> @test_vector_sgt(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_sgt:
  %cmp = icmp sgt <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpgt_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_sge(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_sge:
  %cmp = icmp sge <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpge_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_slt(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_slt:
  %cmp = icmp slt <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmplt_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_sle(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_sle:
  %cmp = icmp sle <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmple_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_eq(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_eq:
  %cmp = icmp eq <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpeq_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_ne(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_ne:
  %cmp = icmp ne <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpne_i s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_ugt(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_ugt:
  %cmp = icmp ugt <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpgt_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_uge(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_uge:
  %cmp = icmp uge <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmpge_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_ult(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_ult:
  %cmp = icmp ult <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmplt_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}

define <16 x i32> @test_vector_ule(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_vector_ule:
  %cmp = icmp ule <16 x i32> %a, %b
  %sext = sext <16 x i1> %cmp to <16 x i32>

  ; CHECK: cmple_u s0, v0, v1
  ; CHECK: move v0, 0
  ; CHECK: move_mask v0, s0, -1

  ret <16 x i32> %sext
}
