; RUN: llc %s -o - | FileCheck %s
;
; Test loading vector and scalar values from the constant pool
;

target triple = "nyuzi-elf-none"

; CHECK: [[CONSTV_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long   0
; CHECK: .long   16
; CHECK: .long   32
; CHECK: .long   48

define <16 x i32> @loadconstv() { ; CHECK-LABEL: loadconstv:
  ; CHECK: load_v v{{[0-9]+}}, [[CONSTV_LBL]]
  ret <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>
}

; CHECK: [[CONSTF_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long  1075419546
define float @loadconstf() { ; CHECK-LABEL: loadconstf:
  ret float 0x4003333340000000
  ; CHECK: load_32 s{{[0-9]+}}, [[CONSTF_LBL]]
}

; Largest positive constant that will fit in the 14-bit immediate field
define i32 @loadconsti_pos_little() { ; CHECK-LABEL: loadconsti_pos_little:
  ret i32 8191
  ; CHECK: move s{{[0-9]+}}, 8191
}

; Largest negative constant that will fit in the 14-bit immediate field
define i32 @loadconsti_neg_little() { ; CHECK-LABEL: loadconsti_neg_little:
  ret i32 -8192
  ; CHECK: move s{{[0-9]+}}, -8192
}

; This only requires a movehi because the low bits aren't set
; One more than loadconsti_pos_little
define i32 @loadconsti_pos_big1() { ; CHECK-LABEL: loadconsti_pos_big1:
  ret i32 8192
  ; CHECK: movehi s0, 1
  ; CHECK-NOT: or
}

; This requires movehi and an or to set the low bits
define i32 @loadconsti_pos_big2() { ; CHECK-LABEL: loadconsti_pos_big2:
  ret i32 8193
  ; CHECK: movehi s0, 1
  ; CHECK: or s0, s0, 1
}

; Largest positive 32-bit constant
define i32 @loadconsti_pos_big3() { ; CHECK-LABEL: loadconsti_pos_big3:
  ret i32 2147483647
  ; CHECK: movehi s0, 262143
  ; CHECK: or s0, s0, 8191
  ; CHECK-NOT: or
}

; This only requires a movehi because the low bits aren't set
define i32 @loadconsti_neg_big1() { ; CHECK-LABEL: loadconsti_neg_big1:
  ret i32 -16384
  ; CHECK: movehi s0, 524286
  ; CHECK-NOT: or
}

; This requires a movehi and an or to set the low bits
define i32 @loadconsti_neg_big2() { ; CHECK-LABEL: loadconsti_neg_big2:
  ret i32 -16385
  ; CHECK: movehi s0, 524285
  ; CHECK: or s0, s0, 8191
}

; Largest negative 32-bit constant
define i32 @loadconsti_neg_big3() { ; CHECK-LABEL: loadconsti_neg_big3:
  ret i32 -2147483648
  ; CHECK: movehi s0, 262144
  ; CHECK-NOT: or
}

; Ensure constant operands are lowered properly
define i32 @largeoperand(i32 %a) { ; CHECK-LABEL: largeoperand:
  %1 = add i32 %a, 1234567

  ; CHECK: movehi [[CONSTREG:s[0-9]+]], 150
  ; CHECK: or [[CONSTREG]], [[CONSTREG]], 5767
  ; CHECK: add_i s0, s0, [[CONSTREG]]

  ret i32 %1
};
