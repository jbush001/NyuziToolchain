; RUN: llc %s -o - | FileCheck %s

;
; Regression test, failure case created by llvm-stress
;

target triple = "nyuzi-none-none"

define void @autogen_SD0() {
BB:
  %Sl591 = select i1 undef, <4 x i32> zeroinitializer, <4 x i32> undef
  br label %CF25227

CF25227:                                          ; preds = %CF25227, %BB
  %Shuff693 = shufflevector <4 x i32> undef, <4 x i32> %Sl591, <4 x i32> <i32 6, i32 0, i32 2, i32 4>
  br label %CF25227

  ; CHECK: b .LBB
}
