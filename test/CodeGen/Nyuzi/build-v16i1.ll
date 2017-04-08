; RUN: llc %s -o - | FileCheck %s
;
; This test validates the v16i1 path of NyuziISelLowering::LowerBUILD_VECTOR,
; mostly the conversion from constant i1 vectors into integer bitmasks.

target triple = "nyuzi"

; Checks that a large i1 vector is correctly mapped
; to an i32 constant pool entry
; CHECK: [[MASK_CP:.LCPI[0-9]+_[0-9]+]]
; CHECK-NEXT: .long 40960 # 0xa000
define <16 x i1> @large_literal() { ; CHECK-LABEL: large_literal:
  ; CHECK: load_32 s0, [[MASK_CP]]
  ; CHECK-NEXT: ret
  ret <16 x i1> <i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 true, i1 false, i1 true>
}

; Checks that a small i1 vector is correctly mapped
; to an i32 immediate
define <16 x i1> @small_literal() { ; CHECK-LABEL: small_literal:
  ; CHECK: move s0, 2053
  ; CHECK-NEXT: ret
  ret <16 x i1> <i1 true, i1 false, i1 true, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 false, i1 true, i1 false, i1 false, i1 false, i1 false>
}

; Checks that the lowering doesn't try to get too smart about splats.
; CHECK: [[MASK_CP:.LCPI[0-9]+_[0-9]+]]
; CHECK-NEXT: .long 65535
define <16 x i1> @splat() { ; CHECK-LABEL: splat:
entry:
  ; CHECK: load_32 s0, [[MASK_CP]]
  ; CHECK-NEXT: ret
  %.splatinsert = insertelement <16 x i1> undef, i1 true, i32 0
  %.splat = shufflevector <16 x i1> %.splatinsert, <16 x i1> undef, <16 x i32> zeroinitializer
  ret <16 x i1> %.splat
}

; Checks the undef handling
define <16 x i1> @undef_lanes() { ; CHECK-LABEL: undef_lanes:
entry:
  ; CHECK: move s0, 5
  ; CHECK-NEXT: ret
  %0 = insertelement <16 x i1> undef, i1 true, i32 0
  %1 = insertelement <16 x i1> %0, i1 true, i32 2
  ret <16 x i1> %1
}


; Checks that non-constant BUILD_VECTOR works
define <16 x i1> @nonconst(i1 %a, i1 %b) { ; CHECK-LABEL: nonconst:
entry:
  ; CHECK-NOT: load_32
  ; CHECK: and s0, s0, 1
  ; CHECK: and s1, s1, 1
  ; CHECK: shl s1, s1, 8
  ; CHECK: or s0, s1, s0
  ; CHECK: shl s0, s0, 5
  %0 = insertelement <16 x i1> zeroinitializer, i1 %a, i32 5
  %1 = insertelement <16 x i1> %0, i1 %b, i32 13
  ret <16 x i1> %1
}

; Checks that constant BUILD_VECTOR with i32 elements works
; This is legal (elements of larger types are truncated),
; but a bit hard to trigger, hence this weird function.
define <16 x i1> @complicated_const_buildvector() { ; CHECK-LABEL: complicated_const_buildvector:
  %a = icmp ult <16 x i32> zeroinitializer, <i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16, i32 16>
  %b = and <16 x i1> <i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true, i1 true>, %a
  ; CHECK: load_32 s0, .LCPI
  ret <16 x i1> %b
}
