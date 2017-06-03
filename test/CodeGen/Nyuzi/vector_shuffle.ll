; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s
;
; This test validates NyuziISelLowering::LowerVECTOR_SHUFFLE, which
; has a bunch of special case optimizations for various shuffle types.
;

target triple = "nyuzi"

; Test that splat works okay for element 0
define <16 x i32> @test_insertelement_splat0(i32 %a) { ; CHECK-LABEL: test_insertelement_splat0:
  %single = insertelement <16 x i32> undef, i32 %a, i32 0
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> zeroinitializer

  ; CHECK: move v0, s0
  ; CHECK-NOT: shuffle

  ret <16 x i32> %splat
}

; Test splat for a different vector lane (7)
define <16 x i32> @test_insertelement_splat7(i32 %a) { ; CHECK-LABEL: test_insertelement_splat7:
  %single = insertelement <16 x i32> undef, i32 %a, i32 7
  %splat = shufflevector <16 x i32> %single, <16 x i32> undef, <16 x i32> <i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7>

  ; CHECK: move v0, s0
  ; CHECK-NOT: shuffle

  ret <16 x i32> %splat
}


; XXX need to test scalar_to_vector


; Test where the result is a splat because all elements are the same
define <16 x i32> @test_splat_elem1(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_splat_elem1:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> <i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7>

  ; CHECK: getlane s0, v0, 7
  ; CHECK: move v0, s0

  ret <16 x i32> %res
}

; Same as test_splat_elem1, but with second parameter
define <16 x i32> @test_splat_elem2(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_splat_elem2:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> <i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17>

  ; CHECK: getlane s0, v1, 1
  ; CHECK: move v0, s0

  ret <16 x i32> %res
}

; Perform a shuffle where both arguments are the same. Ensure it detects that.
define <16 x i32> @identity_shuffle_same_ops(<16 x i32> %a) { ; CHECK-LABEL: identity_shuffle_same_ops:
  %res = shufflevector <16 x i32> %a, <16 x i32> %a, <16 x i32> <i32 0, i32 17, i32 2, i32 19, i32 4, i32 21, i32 6, i32 23, i32 8, i32 25, i32 10, i32 27, i32 12, i32 29, i32 14, i32 31>

  ; CHECK-NOT: shuffle {{v[0-9]+}}
  ; CHECK-NOT: move
  ; CHECK: ret

  ret <16 x i32> %res
}

; Only select items from the first vector. This will be a move.
define <16 x i32> @test1(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test1:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15 >

  ; CHECK-NOT: shuffle
  ; CHECK-NOT: move
  ; CHECK: ret

  ret <16 x i32> %res
}

; Only select items from the second vector. This will be a move.
define <16 x i32> @test2(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test2:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 16, i32 17, i32 18, i32 19, i32 20, i32 21, i32 22, i32 23, i32 24, i32 25, i32 26, i32 27, i32 28, i32 29, i32 30, i32 31>

  ; CHECK-NOT: shuffle
  ; CHECK: move v0, v1

  ret <16 x i32> %res
}

; Select items from both vectors, but same lanes. Will be masked move
define <16 x i32> @masked_move(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: masked_move:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 0, i32 17, i32 2, i32 19, i32 4, i32 21, i32 6, i32 23, i32 8, i32 25, i32 10, i32 27, i32 12, i32 29, i32 14, i32 31>

  ; CHECK: movehi [[TMP1:s[0-9]+]], 5
  ; CHECK: or [[MM_SREG:s[0-9]+]], [[TMP1]], 2730
  ; CHECK-NEXT: move_mask {{v[0-9]+}}, [[MM_SREG]], v1
  ; CHECK-NOT: shuffle {{v[0-9]}}

  ret <16 x i32> %res
}

; Shuffle only vector 1
; CHECK: [[SO1_SHUFFLEVECCP:.LCPI[0-9]+_[0-9]+]]
; CHECK: .long 15
; CHECK: .long 14
; CHECK: .long 13
; CHECK: .long 12
; CHECK: .long 11
; CHECK: .long 10
; CHECK: .long 9
; CHECK: .long 8
; CHECK: .long 7
; CHECK: .long 6
; CHECK: .long 5
; CHECK: .long 4
; CHECK: .long 3
; CHECK: .long 2
; CHECK: .long 1
; CHECK: .long 0

define <16 x i32> @shuffle_only1(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: shuffle_only1:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 15, i32 14, i32 13, i32 12, i32 11, i32 10, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1, i32 0 >

  ; CHECK: movehi s0, hi([[SO1_SHUFFLEVECCP]])
  ; CHECK: or s0, s0, lo([[SO1_SHUFFLEVECCP]])
  ; CHECK: load_v [[SO1_SHUFFLEVEC:v[0-9]+]], (s0)
  ; CHECK-NEXT: shuffle v0, v0, [[SO1_SHUFFLEVEC]]
  ; CHECK-NEXT: ret

  ret <16 x i32> %res
}

; Shuffle only vector 2
; CHECK: [[SO2_SHUFFLEVECCP:.LCPI[0-9]+_[0-9]+]]
; CHECK: .long 15
; CHECK: .long 14
; CHECK: .long 13
; CHECK: .long 12
; CHECK: .long 11
; CHECK: .long 10
; CHECK: .long 9
; CHECK: .long 8
; CHECK: .long 7
; CHECK: .long 6
; CHECK: .long 5
; CHECK: .long 4
; CHECK: .long 3
; CHECK: .long 2
; CHECK: .long 1
; CHECK: .long 0
define <16 x i32> @shuffle_only2(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: shuffle_only2:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 31, i32 30, i32 29, i32 28, i32 27, i32 26, i32 25, i32 24, i32 23, i32 22, i32 21, i32 20, i32 19, i32 18, i32 17, i32 16 >

  ; CHECK: movehi s0, hi([[SO2_SHUFFLEVECCP]])
  ; CHECK: or s0, s0, lo([[SO2_SHUFFLEVECCP]])
  ; CHECK: load_v [[SO2_SHUFFLEVEC:v[0-9]+]], (s0)
  ; CHECK-NEXT: shuffle v0, v1, [[SO2_SHUFFLEVEC]]
  ; CHECK-NEXT: ret

  ret <16 x i32> %res
}

; Shuffle and mix vectors
; CHECK: [[SM_SHUFFLEVECCP:.LCPI[0-9]+_[0-9]+]]
; CHECK: .long 15
; CHECK: .long 14
; CHECK: .long 13
; CHECK: .long 12
; CHECK: .long 11
; CHECK: .long 10
; CHECK: .long 9
; CHECK: .long 8
; CHECK: .long 7
; CHECK: .long 6
; CHECK: .long 5
; CHECK: .long 4
; CHECK: .long 3
; CHECK: .long 2
; CHECK: .long 1
; CHECK: .long 0

define <16 x i32> @test_shuffle_mix(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_shuffle_mix:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> < i32 31, i32 14, i32 29, i32 12, i32 27, i32 10, i32 25, i32 8, i32 23, i32 6, i32 21, i32 4, i32 19, i32 2, i32 17, i32 0 >

  ; CHECK-DAG: movehi s0, hi([[SM_SHUFFLEVECCP]])
  ; CHECK-DAG: or s0, s0, lo([[SM_SHUFFLEVECCP]])
  ; CHECK-DAG: load_v [[SM_SHUFFLEVEC:v[0-9]+]], (s0)
  ; CHECK-DAG: shuffle v0, v0, [[SM_SHUFFLEVEC]]
  ; CHECK-DAG: movehi [[TMP5:s[0-9]+]], 2
  ; CHECK-DAG: or [[SM_MASK:s[0-9]+]], [[TMP5]], 5461
  ; CHECK-DAG: shuffle_mask {{v[0-9]+}}, [[SM_MASK]], v1, [[SM_SHUFFLEVEC]]

  ret <16 x i32> %res
}

; Ensure undef values are handled. Currently, they just map to lane zero, so this will look
; like a single vector shuffle.
define <16 x i32> @test_shuffle_undef(<16 x i32> %a, <16 x i32> %b) { ; CHECK-LABEL: test_shuffle_undef:
  %res = shufflevector <16 x i32> %a, <16 x i32> %b, <16 x i32> <i32 undef, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 8, i32 7, i32 6, i32 5, i32 4, i32 3>

  ; CHECK: shuffle v0, v0, v

  ret <16 x i32> %res
}

; v16i1 shuffles get translated to zext -> v16i32 shuffle -> trunc
define <16 x i1> @test_shuffle_mix_bits(<16 x i1> %a, <16 x i1> %b) { ; CHECK-LABEL: test_shuffle_mix_bits:
  %res = shufflevector <16 x i1> %a, <16 x i1> %b, <16 x i32> < i32 31, i32 14, i32 29, i32 12, i32 27, i32 10, i32 25, i32 8, i32 23, i32 6, i32 21, i32 4, i32 19, i32 2, i32 17, i32 0 >

  ; CHECK-DAG: movehi [[A:s[0-9]+]], hi(.LCPI12_0)
  ; CHECK-DAG: or [[B:s[0-9]+]], [[A]], lo(.LCPI12_0)
  ; CHECK-DAG: load_v [[C:v[0-9]+]], ([[B]])
  ; CHECK-DAG: move [[D:v[0-9]+]], 0
  ; CHECK-DAG: move [[E:v[0-9]+]], [[D]]
  ; CHECK-DAG: move_mask [[D]], s0, 1
  ; CHECK-DAG: movehi [[G:s[0-9]+]], 2
  ; CHECK-DAG: move_mask [[E]], s1, 1
  ; CHECK-DAG: shuffle [[I:v[0-9]+]], [[D]], [[C]]
  ; CHECK-DAG: or [[H:s[0-9]+]], [[G]], 5461
  ; CHECK-DAG: shuffle_mask [[J:v[0-9]+]], [[H]], [[E]], [[C]]
  ; CHECK-DAG: and [[C]], [[J]], 1
  ; CHECK-DAG: cmpeq_i s0, [[C]], 1

  ret <16 x i1> %res
}

