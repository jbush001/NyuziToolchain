; RUN: llc %s -o - | FileCheck %s
;
; Test 'select' LLVM instruction
;

target triple = "nyuzi-elf-none"

; This will use the SELECT_CC opcode
define i32 @seli1(i32 %a) {  ; CHECK-LABEL: seli1:
  %cmp = icmp eq i32 %a, 4

  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, i32 2, i32 3

  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move s{{[0-9]+}}, [0-9]+
  ; [[TRUELABEL]]:

  ret i32 %val
}

; This will use the SELECT opcode, which gets expanded to SELECT_CC
define i32 @seli2(i1 %a) {  ; CHECK-LABEL: seli2:
  %val = select i1 %a, i32 2, i32 3

  ; CHECK: cmpne_i [[PRED:s[0-9]+]], s0, 0
  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move s{{[0-9]+}}, 3
  ; ret
  ; [[TRUELABEL]]:
  ; move s0, 2

  ret i32 %val
}

;
; Tests below have same pattern of SELECT_CC/SELECT
;

define float @self1(float %a, float %b, float %c) {  ; CHECK-LABEL: self1:
  %cmp = fcmp oeq float %a, %b

  ; CHECK: cmpeq_f [[PRED:s[0-9]+]], s0, s1

  %val = select i1 %cmp, float %b, float %c

  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; [[TRUELABEL]]:

  ret float %val
}

define float @self2(i1 %a, float %b, float %c) {  ; CHECK-LABEL: self2:
  %val = select i1 %a, float %b, float %c

  ; CHECK: cmpne_i [[PRED:s[0-9]+]], s0, 0
  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move s{{[0-9]+}}, s2
  ; ret
  ; [[TRUELABEL]]:
  ; move s0, s1

  ret float %val
}

define <16 x i32> @selvi1(i32 %a, <16 x i32> %b, <16 x i32> %c) { ; CHECK-LABEL: selvi1:
  %cmp = icmp eq i32 %a, 4

  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, <16 x i32> %b, <16 x i32> %c

  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move v{{[0-9]+}}, v0
  ; [[TRUELABEL]]:

  ret <16 x i32> %val
}

define <16 x i32> @selvi2(i1 %a, <16 x i32> %b, <16 x i32> %c) { ; CHECK-LABEL: selvi2:
  %val = select i1 %a, <16 x i32> %b, <16 x i32> %c

  ; CHECK: cmpne_i [[PRED:s[0-9]+]], s0, 0
  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; CHECK: move [[MASK:s[0-9]+]], 0
  ; CHECK: b [[FALSELABEL:[\.A-Z0-9a-z_]+]]
  ; CHECK: [[TRUELABEL]]:
  ; CHECK: move [[MASK]], -1
  ; CHECK: [[FALSELABEL]]:
  ; CHECK-DAG: move [[A:v[0-9]+]], [[MASK]]
  ; CHECK-DAG: xor [[B:v[0-9]+]], [[A]], -1
  ; CHECK-DAG: and [[C:v[0-9]+]], v0, [[MASK]]
  ; CHECK-DAG: and [[D:v[0-9]+]], v1, v2
  ; CHECK-DAG: or v0, [[C]], [[D]]
  ; CHECK: ret

  ret <16 x i32> %val
}

define <16 x float> @selvf1(i32 %a, <16 x float> %b, <16 x float> %c) { ; CHECK-LABEL: selvf1:
  %cmp = icmp eq i32 %a, 4
  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, <16 x float> %b, <16 x float> %c
  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move v0, v1
  ; [[TRUELABEL]]:

  ret <16 x float> %val
}

define <16 x float> @selvf2(i1 %a, <16 x float> %b, <16 x float> %c) { ; CHECK-LABEL: selvf2:
  %val = select i1 %a, <16 x float> %b, <16 x float> %c

  ; CHECK: cmpne_i [[PRED:s[0-9]+]], s0, 0
  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; CHECK: move [[MASK:s[0-9]+]], 0
  ; CHECK: b [[FALSELABEL:[\.A-Z0-9a-z_]+]]
  ; CHECK: [[TRUELABEL]]:
  ; CHECK: move [[MASK]], -1
  ; CHECK: [[FALSELABEL]]:
  ; CHECK-DAG: move [[A:v[0-9]+]], [[MASK]]
  ; CHECK-DAG: xor [[B:v[0-9]+]], [[A]], -1
  ; CHECK-DAG: and [[C:v[0-9]+]], v0, [[MASK]]
  ; CHECK-DAG: and [[D:v[0-9]+]], v1, v2
  ; CHECK-DAG: or v0, [[C]], [[D]]
  ; CHECK: ret

  ret <16 x float> %val
}

define <16 x i1> @selmask1(i32 %a, <16 x i1> %b, <16 x i1> %c) { ; CHECK-LABEL: selmask1
  %cmp = icmp eq i32 %a, 4
  ; CHECK: cmpeq_i [[PRED:s[0-9]+]], s0, 4

  %val = select i1 %cmp, <16 x i1> %b, <16 x i1> %c

  ; CHECK: bnz [[PRED]], [[TRUELABEL:[\.A-Z0-9a-z_]+]]
  ; move s{{[0-9]+}}, s0
  ; [[TRUELABEL]]:

  ret <16 x i1> %val
}

define <16 x i1> @selmask2(i1 %a, <16 x i1> %b, <16 x i1> %c) { ; CHECK-LABEL: selmask2
  %val = select i1 %a, <16 x i1> %b, <16 x i1> %c

  ; CHECK: cmpne_i [[RESULT:s[0-9]+]], s0, 0
  ; CHECK: move s0, s1
  ; CHECK: bnz [[RESULT]], [[EXITLABEL:[\.A-Z0-9a-z_]+]]
  ; CHECK: move s0, s2
  ; CHECK: [[EXITLABEL]]:
  ; CHECK: ret

  ret <16 x i1> %val
}

define <16 x i1> @selmask3(<16 x i1> %mask, <16 x i1> %a, <16 x i1> %b) { ; CHECK-LABEL: selmask3
  %val = select <16 x i1> %mask, <16 x i1> %a, <16 x i1> %b

  ; CHECK: movehi s3, 7
  ; CHECK: or s3, s3, 8191
  ; CHECK: and s1, s1, s0
  ; CHECK: xor s0, s0, s3
  ; CHECK: and s0, s2, s0
  ; CHECK: or s0, s1, s0
  ; CHECK: ret

  ret <16 x i1> %val
}
