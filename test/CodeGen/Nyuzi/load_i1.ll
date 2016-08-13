; RUN: llc %s -o - | FileCheck %s
;
; Regression test for issue #40, issue #29
; Make sure extended i1 loads are expanded properly
;

target triple = "nyuzi-elf-none"

@glob = internal unnamed_addr global i1 false, align 4

; This will perform two shifts to properly sign extend the value
define i32 @sextloadi1() { ; CHECK-LABEL: sextloadi1:
  %1 = load i1, i1* @glob, align 4
  %2 = sext i1 %1 to i32

	; CHECK: load_u8 s0, (s0)
	; CHECK: shl s0, s0, 31
	; CHECK: ashr s0, s0, 31

  ret i32 %2
}

define i32 @zextloadi1() { ; CHECK-LABEL: zextloadi1:
  %1 = load i1, i1* @glob, align 4
  %2 = zext i1 %1 to i32

  ; CHECK: load_u8

  ret i32 %2
}
