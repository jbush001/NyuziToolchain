; RUN: llc %s -o - | FileCheck %s
;
; Test passing scalar arguments to a called function.
; This validates NyuziTargetLowering::LowerFormalArguments and
; NyuziTargetLowering::LowerCall
;

target triple = "nyuzi-elf-none"

define i32 @somefunc(float %arg1, i32 %arg2, i32 %arg3,
  i32 %arg4, i32 %arg5, i32 %arg6, i32 %arg7, i32 %arg8,
  i32 %arg9, i32 %arg10, float %arg11, i8 %arg12, i16 %arg13) { ; CHECK-LABEL: somefunc:

  %result = alloca i32

  ; Technically this stack allocation is not necessary since there are no spills.
  ; This might break if the backend implementation changes. The parameter offsets
  ; for the loads depend on this.

  ; CHECK: add_i sp, sp, -64

  ; Floating point register argument
  %1 = fptosi float %arg1 to i32
  %2 = add i32 %1, %arg2

  ; CHECK-DAG: ftoi [[TMP1:s[0-9]+]], s0
  ; CHECK-DAG: add_i [[RES1:s[0-9]+]], [[TMP1]], s1

  ; Integer register argument
  %3 = add i32 %2, %arg3

  ; CHECK-DAG: add_i [[RES2:s[0-9]+]], [[RES1]], s2

  %4 = add i32 %3, %arg4

  ; CHECK-DAG: add_i [[RES3:s[0-9]+]], [[RES2]], s3

  %5 = add i32 %4, %arg5

  ; CHECK-DAG: add_i [[RES4:s[0-9]+]], [[RES3]], s4

  %6 = add i32 %5, %arg6

  ; CHECK-DAG: add_i [[RES5:s[0-9]+]], [[RES4]], s5

  %7 = add i32 %6, %arg7

  ; CHECK-DAG: add_i [[RES6:s[0-9]+]], [[RES5]], s6

  %8 = add i32 %7, %arg8

  ; CHECK-DAG: add_i [[RES7:s[0-9]+]], [[RES6]], s7

  %9 = add i32 %8, %arg9

  ; Stack integer argument
  ; CHECK-DAG: load_32 [[TMP2:s[0-9]+]], 64(sp)
  ; CHECK-DAG: add_i [[RES7:s[0-9]+]], [[RES6]], [[TMP2]]

  %10 = add i32 %9, %arg10

  ; CHECK-DAG: load_32 [[TMP3:s[0-9]+]], 68(sp)
  ; CHECK-DAG: add_i [[RES8:s[0-9]+]], [[RES7]], [[TMP3]]

  ; Stack floating point argument
  %11 = fptosi float %arg11 to i32
  %12 = add i32 %10, %11

  ; CHECK-DAG: load_32 [[TMP4:s[0-9]+]], 72(sp)
  ; CHECK-DAG: ftoi [[TMP5:s[0-9]+]], [[TMP4]]
  ; CHECK-DAG: add_i [[RES9:s[0-9]+]], [[RES8]], [[TMP5]]

  ; Stack i8 argument
  %13 = sext i8 %arg12 to i32
  %14 = add i32 %12, %13

  ; CHECK-DAG: load_s8 [[TMP6:s[0-9]+]], 76(sp)
  ; CHECK-DAG: add_i [[RES10:s[0-9]+]], [[RES9]], [[TMP6]]

  ; Stack i16 argument
  %15 = sext i16 %arg13 to i32
  %16 = add i32 %14, %15

  ; CHECK-DAG: load_s16 [[TMP7:s[0-9]+]], 80(sp)
  ; CHECK-DAG: add_i [[RES11:s[0-9]+]], [[RES10]], [[TMP7]]

  ret i32 %16
}

define i32 @main() {  ; CHECK-LABEL: main:

  %result = call i32 @somefunc(float 1.0, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, float 11.0, i8 12, i16 13)

  ; The first eight arguments will be passed in registers. The remainders will
  ; be copied onto the stack.

  ; CHECK-DAG: move [[PARAMTMP1:s[0-9]+]], 13
  ; CHECK-DAG: store_32 [[PARAMTMP1]], 16(sp)
  ; CHECK-DAG: move [[PARAMTMP2:s[0-9]+]], 12
  ; CHECK-DAG: store_32 [[PARAMTMP2]], 12(sp)
  ; CHECK-DAG: store_32 {{s[0-9]+}}, 8(sp)
  ; CHECK-DAG: move [[PARAMTMP3:s[0-9]+]], 10
  ; CHECK-DAG: store_32 [[PARAMTMP3]], 4(sp)
  ; CHECK-DAG: move [[PARAMTMP4:s[0-9]+]], 9
  ; CHECK-DAG: store_32 [[PARAMTMP4]], (sp)
  ; CHECK-DAG: load_32 s0,
  ; CHECK-DAG: move s1, 2
  ; CHECK-DAG: move s2, 3
  ; CHECK-DAG: move s3, 4
  ; CHECK-DAG: move s4, 5
  ; CHECK-DAG: move s5, 6
  ; CHECK-DAG: move s6, 7
  ; CHECK-DAG: move s7, 8
  ; CHECK: call somefunc

  ret i32 %result
}
