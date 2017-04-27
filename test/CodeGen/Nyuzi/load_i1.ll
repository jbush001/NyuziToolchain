; RUN: llc %s -o - | FileCheck %s
;
; Regression test for issue #40, issue #29
; Make sure extended i1 loads are expanded properly
;

target triple = "nyuzi-elf-none"

@glob = internal unnamed_addr global i1 false, align 4

; This will sign extend the value after loading
define i32 @sextloadi1() { ; CHECK-LABEL: sextloadi1:
  %1 = load i1, i1* @glob, align 4
  %2 = sext i1 %1 to i32

	; CHECK-DAG: movehi [[A:s[0-9]+]], hi(glob)
	; CHECK-DAG: or [[B:s[0-9]+]], [[A]], lo(glob)
	; CHECK-DAG: load_u8 [[C:s[0-9]+]], ([[B]])
	; CHECK-DAG: move [[D:s[0-9]+]], 0
	; CHECK-DAG: and [[E:s[0-9]+]], [[C]], 1
	; CHECK-DAG: sub_i s0, [[D]], [[E]]

  ret i32 %2
}

define i32 @zextloadi1() { ; CHECK-LABEL: zextloadi1:
  %1 = load i1, i1* @glob, align 4
  %2 = zext i1 %1 to i32

  ; CHECK: load_u8

  ret i32 %2
}
