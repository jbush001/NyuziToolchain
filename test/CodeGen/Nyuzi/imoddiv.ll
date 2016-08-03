; RUN: llc %s -o - | FileCheck %s
;
; Test integer modulus/division. There are no native instructions for these, so
; they are converted to runtime library calls.
;

target triple = "nyuzi-elf-none"

define i32 @urem32(i32 %a, i32 %b) { ; CHECK-LABEL: urem32:
  %1 = urem i32 %a, %b

  ; CHECK: call __umodsi3

  ret i32 %1
}

define i32 @srem32(i32 %a, i32 %b) { ; CHECK-LABEL: srem32:
  %1 = srem i32 %a, %b

  ; CHECK: call __modsi3

  ret i32 %1
}

define i32 @udiv32(i32 %a, i32 %b) { ; CHECK-LABEL: udiv32:
  %1 = udiv i32 %a, %b

  ; CHECK: call __udivsi3

  ret i32 %1
}

define i32 @sdiv32(i32 %a, i32 %b) { ; CHECK-LABEL: sdiv32:
  %1 = sdiv i32 %a, %b

  ; CHECK: call __divsi3

  ret i32 %1
}

define i64 @urem64(i64 %a, i64 %b) { ; CHECK-LABEL: urem64:
  %1 = urem i64 %a, %b

  ; CHECK: call __umoddi3

  ret i64 %1
}

define i64 @srem64(i64 %a, i64 %b) { ; CHECK-LABEL: srem64:
  %1 = srem i64 %a, %b

  ; CHECK: call __moddi3

  ret i64 %1
}

define i64 @udiv64(i64 %a, i64 %b) { ; CHECK-LABEL: udiv64:
  %1 = udiv i64 %a, %b

  ; CHECK: call __udivdi3

  ret i64 %1
}

define i64 @sdiv64(i64 %a, i64 %b) { ; CHECK-LABEL: sdiv64:
  %1 = sdiv i64 %a, %b

  ; CHECK: call __divdi3

  ret i64 %1
}
