; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define void @dflush(i32 %ptr) {
	call void asm sideeffect "dflush $0", "s" (i32 %ptr)

	; CHECK: dflush s0

	ret void
}

define <16 x i32> @test_vadd(<16 x i32> %a, i32 %b)  { ; CHECK: test_vadd:
  %1 = tail call <16 x i32> asm sideeffect "add $0, $1, $2", "=v,v,s"(<16 x i32> %a, i32 %b)

  ; CHECK: #APP
  ; CHECK: add v0, v0, s0
  ; CHECK: #NO_APP

  ret <16 x i32> %1
}
