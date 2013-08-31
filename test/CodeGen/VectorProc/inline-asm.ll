; RUN: llc %s -o - | FileCheck %s
; XFAIL:

target triple = "vectorproc"

define void @dflush(i32 %ptr) {	
	call void asm sideeffect "dflush $0", "r" (i32 %ptr) #1

	; CHECK: dflush s0

	ret void
}

