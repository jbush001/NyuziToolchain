; RUN: llc %s -o - | FileCheck %s
;
; Test passing vector arguments.
; This validates NyuziTargetLowering::LowerFormalArguments and
; NyuziTargetLowering::LowerCall
;

target triple = "nyuzi-elf-none"

define <16 x i32> @somefunc(i32 %arg0, <16 x float> %arg1, <16 x i32> %arg2, <16 x i32> %arg3,
  <16 x i32> %arg4, <16 x i32> %arg5, <16 x i32> %arg6, <16 x i32> %arg7, <16 x i32> %arg8,
  <16 x i32> %arg9, <16 x i32> %arg10, <16 x float> %arg11) { ; CHECK-LABEL: somefunc:

  %result = alloca <16 x i32>

  ; Technically this stack allocation is not necessary since there are no spills.
  ; This might break if the backend implementation changes. The parameter offsets
  ; for the loads depend on this.

  ; CHECK: add_i sp, sp, -64

  ; Floating point register argument
  %1 = fptosi <16 x float> %arg1 to <16 x i32>
  %2 = add <16 x i32> %1, %arg2

  ; CHECK-DAG: ftoi [[TMP1:v[0-9]+]], v0
  ; CHECK-DAG: add_i [[RES1:v[0-9]+]], [[TMP1]], v1

  ; Integer register argument
  %3 = add <16 x i32> %2, %arg3

  ; CHECK-DAG: add_i [[RES2:v[0-9]+]], [[RES1]], v2

  %4 = add <16 x i32> %3, %arg4

  ; CHECK-DAG: add_i [[RES3:v[0-9]+]], [[RES2]], v3

  %5 = add <16 x i32> %4, %arg5

  ; CHECK-DAG: add_i [[RES4:v[0-9]+]], [[RES3]], v4

  %6 = add <16 x i32> %5, %arg6

  ; CHECK-DAG: add_i [[RES5:v[0-9]+]], [[RES4]], v5

  %7 = add <16 x i32> %6, %arg7

  ; CHECK-DAG: add_i [[RES6:v[0-9]+]], [[RES5]], v6

  %8 = add <16 x i32> %7, %arg8

  ; CHECK-DAG: add_i [[RES7:v[0-9]+]], [[RES6]], v7

  %9 = add <16 x i32> %8, %arg9

  ; Stack integer argument
  ; CHECK-DAG: load_v [[TMP2:v[0-9]+]], 64(sp)
  ; CHECK-DAG: add_i [[RES7:v[0-9]+]], [[RES6]], [[TMP2]]

  %10 = add <16 x i32> %9, %arg10

  ; CHECK-DAG: load_v [[TMP3:v[0-9]+]], 128(sp)
  ; CHECK-DAG: add_i [[RES8:v[0-9]+]], [[RES7]], [[TMP3]]

  ; Stack floating point argument
  %11 = fptosi <16 x float> %arg11 to <16 x i32>
  %12 = add <16 x i32> %10, %11

  ; CHECK-DAG: load_v [[TMP4:v[0-9]+]], 192(sp)
  ; CHECK-DAG: ftoi [[TMP5:v[0-9]+]], [[TMP4]]
  ; CHECK-DAG: add_i v{{[0-9]+}}, [[RES8]], [[TMP5]]

  ret <16 x i32> %12
}

define <16 x i32> @main() {  ; CHECK-LABEL: main:

  %result = call <16 x i32> @somefunc(i32 123,
    <16 x float> <float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0>,
    <16 x i32> <i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2>,
    <16 x i32> <i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3>,
    <16 x i32> <i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4>,
    <16 x i32> <i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5>,
    <16 x i32> <i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6>,
    <16 x i32> <i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7>,
    <16 x i32> <i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8>,
    <16 x i32> <i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9>,
    <16 x i32> <i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10>,
    <16 x float> <float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0, float 11.0>)

  ; The first eight arguments will be passed in registers. The remainders will
  ; be copied onto the stack.

  ; CHECK-DAG: store_v {{v[0-9]+}}, 128(sp)
  ; CHECK-DAG: move [[TMPVEC2:v[0-9]+]], 10
  ; CHECK-DAG: store_v [[TMPVEC2]], 64(sp)
  ; CHECK-DAG: move [[TMPVEC3:v[0-9]+]], 9
  ; CHECK-DAG: store_v [[TMPVEC3]], (sp)
  ; CHECK-DAG: move s0, 123
  ; CHECK-DAG: move v0, {{s[0-9]+}}
  ; CHECK-DAG: move v1, 2
  ; CHECK-DAG: move v2, 3
  ; CHECK-DAG: move v3, 4
  ; CHECK-DAG: move v4, 5
  ; CHECK-DAG: move v5, 6
  ; CHECK-DAG: move v6, 7
  ; CHECK-DAG: move v7, 8
  ; CHECK: call somefunc

  ret <16 x i32> %result
}
