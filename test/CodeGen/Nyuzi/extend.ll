; RUN: llc %s -o - | FileCheck %s
;
; Test integer sign extension
;

target triple = "nyuzi-elf-none"

define i32 @test_sext8(i8 %v) { ; CHECK-LABEL: test_sext8:
  %tmp1 = sext i8 %v to i32

  ; CHECK: sext_8 s0, s0

  ret i32 %tmp1
}

define i32 @test_zext8(i8 %v) { ; CHECK-LABEL: test_zext8:
  %tmp1 = zext i8 %v to i32

  ; CHECK: and s0, s0, 255

  ret i32 %tmp1
}

define i32 @test_sext16(i16 %v) { ; CHECK-LABEL: test_sext16:
  %tmp1 = sext i16 %v to i32

  ; CHECK: sext_16 s0, s0

  ret i32 %tmp1
}

define i32 @test_zext16(i16 %v) { ; CHECK-LABEL: test_zext16:
  %tmp1 = zext i16 %v to i32

  ; The mask is large enough that it needs to be loaded separately
  ; and s0, s0, s{{[0-9]+}}

  ret i32 %tmp1
}

define <16 x i32> @test_sext8v(<16 x i8> %v) { ; CHECK-LABEL: test_sext8v:
  %tmp1 = sext <16 x i8> %v to <16 x i32>

  ; CHECK: sext_8 v0, v0

  ret <16 x i32> %tmp1
}

define <16 x i32> @test_zext8v(<16 x i8> %v) { ; CHECK-LABEL: test_zext8v:
  %tmp1 = zext <16 x i8> %v to <16 x i32>

  ; CHECK: and v0, v0, 255

  ret <16 x i32> %tmp1
}

define <16 x i32> @test_sext16v(<16 x i16> %v) { ; CHECK-LABEL: test_sext16v:
  %tmp1 = sext <16 x i16> %v to <16 x i32>

  ; CHECK: sext_16 v0, v0

  ret <16 x i32> %tmp1
}

define <16 x i32> @test_zext16v(<16 x i16> %v) { ; CHECK-LABEL: test_zext16v:
  %tmp1 = zext <16 x i16> %v to <16 x i32>

  ; The mask is large enough that it needs to be loaded from the constant pool.
  ; and s0, s0, s{{[0-9]+}}

  ret <16 x i32> %tmp1
}
