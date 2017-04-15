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

define i32 @loadconsti_pos_little() { ; CHECK-LABEL: loadconsti_pos_little:
  ret i32 13
  ; CHECK: move s{{[0-9]+}}, 13
}

define i32 @loadconsti_neg_little() { ; CHECK-LABEL: loadconsti_neg_little:
  ret i32 -13
  ; CHECK: move s{{[0-9]+}}, -13
}

define i32 @loadconsti_big_hionly() { ; CHECK-LABEL: loadconsti_big_hionly:
  ret i32 305455104  ; 0x1234e000
  ; CHECK: movehi s0, 37287
  ; CHECK-NOT: or
}

define i32 @loadconsti_big() { ; CHECK-LABEL: loadconsti_big:
  ret i32 -4123456780
  ; CHECK: movehi s0, 20936
  ; CHECK: or s0, s0, 2804
}

define i32 @largeoperand(i32 %a) { ; CHECK-LABEL: largeoperand:
  %1 = add i32 %a, 1234567

    ; CHECK: movehi [[CONSTREG:s[0-9]+]], 150
	  ; CHECK: or [[CONSTREG]], [[CONSTREG]], 5767
    ; CHECK: add_i s0, s0, [[CONSTREG]]

  ret i32 %1
};
