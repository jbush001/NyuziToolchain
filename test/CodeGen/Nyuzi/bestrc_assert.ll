; RUN: llc %s -o - | FileCheck %s
;
; Regression test for issue #11:
; Assertion failed: (BestRC && "Couldn't find the register class"), function getMinimalPhysRegClass,
;      file NyuziToolchain/lib/CodeGen/TargetRegisterInfo.cpp, line 124.
; The problem was never directly fixed, but went away when the call to
; "setSchedulingPreference(Sched::RegPressure)" was removed from NyuziTargetLowering.
;

target triple = "nyuzi-elf-none"

declare void @printf(i8* nocapture readonly, ...)

@.str = private unnamed_addr constant [13 x i8] c"swap %d %d: \00", align 1

define void @bad(i32 %i) {
  %rem = srem i32 13, %i
  tail call void (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @.str, i32 0, i32 0), i32 %i, i32 %rem)

  ; CHECK: move s0, 13
  ; CHECK: call __modsi3
  ; CHECK: movehi s0, hi(.L.str)
  ; CHECK: or s0, s0, lo(.L.str)
  ; CHECK: store_32 s0, (sp)
  ; CHECK: call printf

  ret void
}

