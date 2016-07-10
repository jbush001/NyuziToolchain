; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

define i32 @seli(i32 %a) {  ;CHECK: seli:
  %cmp = icmp eq i32 %a, 4

  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, i32 2, i32 3

  ; CHECK: btrue [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move s{{[0-9]+}}, [0-9]+
  ; [[TRUELABEL]]:

  ret i32 %val
}

define float @self(float %a, float %b, float %c) {  ;CHECK: self:
  %cmp = fcmp oeq float %a, %b

  ; CHECK: cmpeq_f [[PRED:s[0-9]+]], s0, s1

  %val = select i1 %cmp, float %b, float %c

  ; CHECK: btrue [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; [[TRUELABEL]]:

  ret float %val
}

define <16 x i32> @selvi(i32 %a, <16 x i32> %b, <16 x i32> %c) {  ; CHECK: selvi:
  %cmp = icmp eq i32 %a, 4

  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, <16 x i32> %b, <16 x i32> %c

  ; CHECK: btrue [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move v{{[0-9]+}}, v0
  ; [[TRUELABEL]]:

  ret <16 x i32> %val
}

define <16 x float> @selvf(i32 %a, <16 x float> %b, <16 x float> %c) {  ; CHECK: selvf:
  %cmp = icmp eq i32 %a, 4
  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, <16 x float> %b, <16 x float> %c
  ; CHECK: btrue [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move v{{[0-9]+}}, v0
  ; [[TRUELABEL]]:

  ret <16 x float> %val
}
