; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

; CHECK: [[CONSTV_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long   0
; CHECK: .long   16
; CHECK: .long   32
; CHECK: .long   48

define <16 x i32> @loadconstv() {  ; CHECK: loadconstv
  ; CHECK: load_v v{{[0-9]+}}, [[CONSTV_LBL]]
  ret <16 x i32> <i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48, i32 0, i32 16, i32 32, i32 48>
}

; CHECK: [[CONSTF_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long  1075419546
define float @loadconstf() {  ; CHECK: loadconstf
  ret float 0x4003333340000000
  ; CHECK: load_32 s{{[0-9]+}}, [[CONSTF_LBL]]
}

define i32 @loadconsti_little() {  ; CHECK: loadconsti_little
  ret i32 13
  ; CHECK: move s{{[0-9]+}}, 13
}

; CHECK: [[CONSTI_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long 3735928559
define i32 @loadconsti_big() {  ; CHECK: loadconsti_big
  ret i32 -559038737
  ; CHECK: load_32 s{{[0-9]+}}, [[CONSTI_LBL]]
}

; Ensures the backend creates constant pool entries when
; instruction operands won't fit in the immediate field
; CHECK: [[CONSTOP_LBL:\.L[A-Z0-9_]+]]:
; CHECK: .long 1234567
define i32 @largeoperand(i32 %a) { ;  CHECK: largeoperand
  %1 = add i32 %a, 1234567

    ; CHECK: load_32 [[CONSTREG:s[0-9]+]], [[CONSTOP_LBL]]
    ; CHECK: add_i s0, s0, [[CONSTREG]]

  ret i32 %1
};
