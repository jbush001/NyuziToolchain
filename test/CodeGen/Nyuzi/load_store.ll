; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

;
; Validate all variants of loads/stores:
; - 8, 16, and 32 bit integer values with and without sign extension
; - Floating point values (they use the same registers/instructions, but ensure
;   LLVM matches types properly).
; - Immediate pointer offset values
; - Vector/Scalar types
;

; The struct is used to validate different pointer offsets (via getlementptr)
%struct.foo = type { i32, i16, i16, i8, i8, i8, i8, float }

define i32 @test_load_u32(%struct.foo* %f) {    ; CHECK: test_load_u32:
  %a = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 0
  %1 = load i32, i32* %a, align 4

  ; CHECK: load_32 s0, (s0)

  ret i32 %1
}

define i32 @test_load_u16(%struct.foo* %f) {    ; CHECK: test_load_u16:
  %b = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 1
  %1 = load i16, i16* %b, align 4
  %conv = zext i16 %1 to i32

  ; CHECK: load_u16 s0, 4(s0)

  ret i32 %conv
}

define i32 @test_load_s16(%struct.foo* %f) {    ; CHECK: test_load_s16:
  %c = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 2
  %1 = load i16, i16* %c, align 2
  %conv = sext i16 %1 to i32

  ; CHECK: load_s16 s0, 6(s0)

  ret i32 %conv
}

define i32 @test_load_u8(%struct.foo* %f) {     ; CHECK: test_load_u8:
  %d = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 3
  %1 = load i8, i8* %d, align 4
  %conv = zext i8 %1 to i32

  ; CHECK: load_u8 s0, 8(s0)

  ret i32 %conv
}

define i32 @test_load_s8(%struct.foo* %f) {     ; CHECK: test_load_s8:
  %e = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 4
  %1 = load i8, i8* %e, align 1
  %conv = sext i8 %1 to i32

  ; CHECK: load_s8 s0, 9(s0)

  ret i32 %conv
}

define float @test_load_float(%struct.foo* %f) {     ; CHECK: test_load_float:
  %e = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 7
  %1 = load float, float* %e, align 4

  ; CHECK: load_32 s0, 12(s0)

  ret float %1
}

define void @test_store_u32(%struct.foo* nocapture %f, i32 %value) {    ; CHECK: test_store_u32:
  %a = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 0
  store i32 %value, i32* %a, align 4

  ; CHECK: store_32 s1, (s0)

  ret void
}

define void @test_store_u16(%struct.foo* nocapture %f, i16 zeroext %value) {      ; CHECK: test_store_u16:
  %b = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 2
  store i16 %value, i16* %b, align 4

  ; CHECK: store_16 s1, 6(s0)

  ret void
}

define void @test_store_u8(%struct.foo* nocapture %f, i8 zeroext %value) {       ; CHECK: test_store_u8:
  %d = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 4
  store i8 %value, i8* %d, align 4

  ; CHECK: store_8 s1, 9(s0)

  ret void
}

define void @test_store_float(%struct.foo* nocapture %f, float %value) {    ; CHECK: test_store_float:
  %a = getelementptr inbounds %struct.foo, %struct.foo* %f, i32 0, i32 7
  store float %value, float* %a, align 4

  ; CHECK: store_32 s1, 12(s0)

  ret void
}

; Vector moves take an array of vectors as the pointer to validate immediate
; offsets.

define void @storeivec(<16 x i32>* %array, <16 x i32> %val1, <16 x i32> %val2) { ; CHECK: storeivec:
  store <16 x i32> %val1, <16 x i32>* %array, align 64

  ; CHECK: store_v v0, (s0)

  %arrayidx1 = getelementptr inbounds <16 x i32>, <16 x i32>* %array, i32 1
  store <16 x i32> %val2, <16 x i32>* %arrayidx1, align 64

  ; CHECK: store_v v1, 64(s0)

  ret void
}

define void @storefvec(<16 x float>* %array, <16 x float> %val1, <16 x float> %val2) { ; CHECK: storefvec:
  store <16 x float> %val1, <16 x float>* %array, align 64

  ; CHECK: store_v v0, (s0)

  %arrayidx1 = getelementptr inbounds <16 x float>, <16 x float>* %array, i32 1
  store <16 x float> %val2, <16 x float>* %arrayidx1, align 64

  ; CHECK: store_v v1, 64(s0)

  ret void
}

define <16 x i32> @loadivec(<16 x i32>* %array) { ; CHECK: loadivec:
  %ptr = getelementptr inbounds <16 x i32>, <16 x i32>* %array, i32 1
  %tmp = load <16 x i32>, <16 x i32>* %ptr

  ; CHECK: load_v v0, 64(s0)

  ret <16 x i32> %tmp
}

define <16 x float> @loadfvec(<16 x float>* %array) { ; CHECK: loadfvec:
  %ptr = getelementptr inbounds <16 x float>, <16 x float>* %array, i32 1
  %tmp = load <16 x float>, <16 x float>* %ptr

  ; CHECK: load_v v0, 64(s0)

  ret <16 x float> %tmp
}
