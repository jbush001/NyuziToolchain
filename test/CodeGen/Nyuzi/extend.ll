; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

define i32 @sext8(i8 %v) {      ; CHECK: sext8
  %tmp1 = sext i8 %v to i32

  ; CHECK: sext_8 s{{[0-9]+}}, s{{[0-9]+}}

  ret i32 %tmp1
}

define i32 @zext8(i8 %v) {     ; CHECK: zext8
  %tmp1 = zext i8 %v to i32

  ; CHECK: and s{{[0-9]+}}, s{{[0-9]+}}, 255

  ret i32 %tmp1
}

define i32 @sext16(i16 %v) {    ; CHECK: sext16
  %tmp1 = sext i16 %v to i32

  ; CHECK: sext_16 s{{[0-9]+}}, s{{[0-9]+}}

  ret i32 %tmp1
}

define i32 @zext16(i16 %v) {    ; CHECK: zext16
  %tmp1 = zext i16 %v to i32

  ; and s{{[0-9]+}}, s{{[0-9]+}}, s{{[0-9]+}}

  ret i32 %tmp1
}
