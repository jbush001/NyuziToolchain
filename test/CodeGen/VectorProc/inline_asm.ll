; RUN: llc -mtriple vectorproc-elf %s -o - | FileCheck %s

target triple = "vectorproc"

define void @dflush(i32 %ptr) {	
	call void asm sideeffect "dflush $0", "s" (i32 %ptr) #1

	; CHECK: dflush s0

	ret void
}

