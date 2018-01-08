; RUN: llc %s -o - | FileCheck %s -check-prefix=CHECK-STATIC
; RUN: llc %s -o - -relocation-model=pic | FileCheck %s -check-prefix=CHECK-PIC
;
; Test loading vector and scalar values from the constant pool
;

target triple = "nyuzi-elf-none"

; CHECK-STATIC: [[CONSTV_LBL:\.L[A-Z0-9_]+]]:
; CHECK-STATIC: .long   0
; CHECK-STATIC: .long   16
; CHECK-STATIC: .long   32
; CHECK-STATIC: .long   48

; CHECK-PIC: [[CONSTV_LBL:\.L[A-Z0-9_]+]]:


define <16 x i32> @loadconstv() { ; CHECK-STATIC-LABEL: loadconstv:
  ; CHECK-STATIC: movehi s0, hi([[CONSTV_LBL]])
  ; CHECK-STATIC: or s0, s0, lo([[CONSTV_LBL]])
  ; CHECK-STATIC: load_v v{{[0-9]+}}, (s0)

	; CHECK-PIC: load_32 s0, got([[CONSTV_LBL]])(gp)
  ; CHECK-PIC: load_v v{{[0-9]+}}, (s0)

  ret <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>
}

; CHECK-STATIC: [[CONSTF_LBL:\.L[A-Z0-9_]+]]:
; CHECK-STATIC: .long  1075419546
; CHECK-PIC: [[CONSTF_LBL:\.L[A-Z0-9_]+]]:
define float @loadconstf() { ; CHECK-STATIC-LABEL: loadconstf:
  ret float 0x4003333340000000
  ; CHECK-STATIC: movehi s0, hi([[CONSTF_LBL]])
  ; CHECK-STATIC: or s0, s0, lo([[CONSTF_LBL]])
  ; CHECK-STATIC: load_32 s{{[0-9]+}}, (s0)

	; CHECK-PIC: load_32 s0, got([[CONSTF_LBL]])(gp)
	; CHECK-PIC: load_32 s{{[0-9]+}}, (s0)
}

; Largest positive constant that will fit in the 14-bit immediate field
define i32 @loadconsti_pos_little() { ; CHECK-STATIC-LABEL: loadconsti_pos_little:
  ret i32 8191
  ; CHECK-STATIC: move s{{[0-9]+}}, 8191
}

; Largest negative constant that will fit in the 14-bit immediate field
define i32 @loadconsti_neg_little() { ; CHECK-STATIC-LABEL: loadconsti_neg_little:
  ret i32 -8192
  ; CHECK-STATIC: move s{{[0-9]+}}, -8192
}

; This only requires a movehi because the low bits aren't set
; One more than loadconsti_pos_little
define i32 @loadconsti_pos_big1() { ; CHECK-STATIC-LABEL: loadconsti_pos_big1:
  ret i32 8192
  ; CHECK-STATIC: movehi s0, 1
  ; CHECK-STATIC-NOT: or
}

; This requires movehi and an or to set the low bits
define i32 @loadconsti_pos_big2() { ; CHECK-STATIC-LABEL: loadconsti_pos_big2:
  ret i32 8193
  ; CHECK-STATIC: movehi s0, 1
  ; CHECK-STATIC: or s0, s0, 1
}

; Largest positive 32-bit constant
define i32 @loadconsti_pos_big3() { ; CHECK-STATIC-LABEL: loadconsti_pos_big3:
  ret i32 2147483647
  ; CHECK-STATIC: movehi s0, 262143
  ; CHECK-STATIC: or s0, s0, 8191
  ; CHECK-STATIC-NOT: or
}

; This only requires a movehi because the low bits aren't set
define i32 @loadconsti_neg_big1() { ; CHECK-STATIC-LABEL: loadconsti_neg_big1:
  ret i32 -16384
  ; CHECK-STATIC: movehi s0, 524286
  ; CHECK-STATIC-NOT: or
}

; This requires a movehi and an or to set the low bits
define i32 @loadconsti_neg_big2() { ; CHECK-STATIC-LABEL: loadconsti_neg_big2:
  ret i32 -16385
  ; CHECK-STATIC: movehi s0, 524285
  ; CHECK-STATIC: or s0, s0, 8191
}

; Largest negative 32-bit constant
define i32 @loadconsti_neg_big3() { ; CHECK-STATIC-LABEL: loadconsti_neg_big3:
  ret i32 -2147483648
  ; CHECK-STATIC: movehi s0, 262144
  ; CHECK-STATIC-NOT: or
}

; Ensure constant operands are lowered properly
define i32 @largeoperand(i32 %a) { ; CHECK-STATIC-LABEL: largeoperand:
  %1 = add i32 %a, 1234567

  ; CHECK-STATIC: movehi [[CONSTREG:s[0-9]+]], 150
  ; CHECK-STATIC: or [[CONSTREG]], [[CONSTREG]], 5767
  ; CHECK-STATIC: add_i s0, s0, [[CONSTREG]]

  ret i32 %1
};
