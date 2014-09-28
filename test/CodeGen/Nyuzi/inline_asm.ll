; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

define void @dflush(i32 %ptr) {	
	call void asm sideeffect "dflush $0", "s" (i32 %ptr) #1

	; CHECK: dflush s0

	ret void
}

