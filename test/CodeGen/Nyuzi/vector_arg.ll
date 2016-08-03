; RUN: llc %s -o - | FileCheck %s
;
; Test passing vector arguments. There is one scalar arg here to ensure it
; doesn't mess up vector argument handling.
;

target triple = "nyuzi-elf-none"

define <16 x i32> @somefunc(i32 %arg0, <16 x i32> %arg1, <16 x i32> %arg2, <16 x i32> %arg3,
  <16 x i32> %arg4, <16 x i32> %arg5, <16 x i32> %arg6, <16 x i32> %arg7, <16 x i32> %arg8,
  <16 x i32> %arg9, <16 x i32> %arg10) { ; CHECK-LABEL: somefunc:

  %result = alloca <16 x i32>

  ; Technically this stack allocation is not necessary since there are no spills.
  ; This might break if the backend implementation changes. The parameter offsets
  ; for the loads depend on this.

  ; CHECK: add_i sp, sp, -64

  %1 = add <16 x i32> %arg1, %arg2

  ; CHECK: add_i [[RES1:v[0-9]+]], v0, v1

  %2 = add <16 x i32> %1, %arg3

  ; CHECK: add_i [[RES2:v[0-9]+]], [[RES1]], v2

  %3 = add <16 x i32> %2, %arg4

  ; CHECK: add_i [[RES3:v[0-9]+]], [[RES2]], v3

  %4 = add <16 x i32> %3, %arg5

  ; CHECK: add_i [[RES4:v[0-9]+]], [[RES3]], v4

  %5 = add <16 x i32> %4, %arg6

  ; CHECK: add_i [[RES5:v[0-9]+]], [[RES4]], v5

  %6 = add <16 x i32> %5, %arg7

  ; CHECK: add_i [[RES6:v[0-9]+]], [[RES5]], v6

  %7 = add <16 x i32> %6, %arg8

  ; CHECK: add_i [[RES7:v[0-9]+]], [[RES6]], v7

  %8 = add <16 x i32> %7, %arg9

  ; Check that these are loaded from the stack
  ; CHECK: load_v [[TMPREG1:v[0-9]+]], 64(sp)
  ; CHECK: add_i [[RES7:v[0-9]+]], [[RES6]], [[TMPREG1]]

  %9 = add <16 x i32> %8, %arg10

  ; CHECK: load_v [[TMPREG2:v[0-9]+]], 128(sp)
  ; CHECK: add_i v{{[0-9]+}}, [[RES7]], [[TMPREG2]]

  ret <16 x i32> %9
}

define <16 x i32> @main() {  ; CHECK-LABEL: main:

  %result = call <16 x i32> @somefunc(i32 123,
    <16 x i32> <i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>,
    <16 x i32> <i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2, i32 2>,
    <16 x i32> <i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3>,
    <16 x i32> <i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4, i32 4>,
    <16 x i32> <i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5>,
    <16 x i32> <i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6, i32 6>,
    <16 x i32> <i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7>,
    <16 x i32> <i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8, i32 8>,
    <16 x i32> <i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9>,
    <16 x i32> <i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10, i32 10>)

  ; The first eight arguments will be passed in registers. The remainders will
  ; be copied onto the stack.

  ; CHECK: move [[TMPVEC1:v[0-9]+]], 10
  ; CHECK: store_v [[TMPVEC1]], 64(sp)
  ; CHECK: move [[TMPVEC2:v[0-9]+]], 9
  ; CHECK: store_v [[TMPVEC2]], (sp)
  ; CHECK: move s0, 123
  ; CHECK: move v0, 1
  ; CHECK: move v1, 2
  ; CHECK: move v2, 3
  ; CHECK: move v3, 4
  ; CHECK: move v4, 5
  ; CHECK: move v5, 6
  ; CHECK: move v6, 7
  ; CHECK: move v7, 8
  ; CHECK: call somefunc

  ret <16 x i32> %result
}
