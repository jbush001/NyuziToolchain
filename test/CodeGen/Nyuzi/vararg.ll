; RUN: llc %s -o - | FileCheck %s
;
; Test variable argument functions work correctly
;

target triple = "nyuzi-elf-none"

declare void @llvm.va_start(i8*)
declare void @llvm.va_end(i8*)

@glob0 = common local_unnamed_addr global i32 0, align 4
@glob1 = common local_unnamed_addr global i8* null, align 4
@glob2 = common local_unnamed_addr global float 0.000000e+00, align 4
@glob3 = common local_unnamed_addr global <16 x i32> zeroinitializer, align 64

define void @test_callee_vararg(i32 %foo, ...) { ; CHECK-LABEL: test_callee_vararg:
  %ap = alloca i8*, align 4
  %1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %1)
  store i32 %foo, i32* @glob0, align 4
  %2 = va_arg i8** %ap, i8*
  store i8* %2, i8** @glob1, align 4
  %3 = va_arg i8** %ap, float
  store float %3, float* @glob2, align 4
  %4 = va_arg i8** %ap, <16 x i32>
  store <16 x i32> %4, <16 x i32>* @glob3, align 64
  call void @llvm.va_end(i8* %1)
  ret void

  ; XXX hard to check the rest
  ; CHECK: load_v v0, (s0)
}

define void @test_caller_vararg(i32 %val1, float %val2, i8* %val3, <16 x i32> %val4) { ; CHECK-LABEL: test_caller_vararg:
  ; CHECK: test_caller_vararg

  tail call void (i32, ...) @test_callee_vararg(i32 1, i32 %val1, float %val2, i8* %val3, <16 x i32> %val4)
  ret void

  ; Ensure this stores all arguments in the proper location on the stack
  ; CHECK: store_v v0, 64(sp)
  ; CHECK: store_32 s2, 12(sp)
  ; CHECK: store_32 s1, 8(sp)
  ; CHECK: store_32 s0, 4(sp)
  ; CHECK: move s0, 1
  ; CHECK: store_32 s0, (sp)
  ; CHECK: call test_callee_vararg
}
