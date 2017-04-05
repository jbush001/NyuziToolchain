; RUN: llc %s -o - | FileCheck %s
;
; This test validates loads and stores of v16i1.

target triple = "nyuzi"

; Test basic loads and stores
define <16 x i1> @replace(<16 x i1>*, <16 x i1>) { ; CHECK-LABEL: replace:
entry:
  %result = load <16 x i1>, <16 x i1>* %0
  store <16 x i1> %1, <16 x i1>* %0

  ; CHECK: load_u16 s2, (s0)
  ; CHECK: store_16 s1, (s0)
  ; CHECK: move s0, s2

  ret <16 x i1> %result
}

; Test receiving parameters on the stack
define <16 x i1> @stack_params(i32, i32, i32, i32, i32, i32, i32, i32, <16 x i1>) { ; CHECK-LABEL: stack_params:
entry:
	; CHECK: load_u16 s0, (sp)
	ret <16 x i1> %8
}

; Test passing parameters on the stack
define void @pass_stack_params() { ; CHECK-LABEL: pass_stack_params:
entry:
	; CHECK: move [[MASK_PARAM:s[0-9]+]], 0
	; CHECK: store_16 [[MASK_PARAM]], (sp)
	; CHECK: call stack_params
	call <16 x i1> @stack_params(i32 42, i32 42, i32 42, i32 42, i32 42, i32 42, i32 42, i32 42, <16 x i1> zeroinitializer)
	ret void
}
