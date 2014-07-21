; RUN: llc -mtriple vectorproc-elf %s -o - | FileCheck %s

define i32 @atomic_add_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_add_reg:
	%tmp = atomicrmw volatile add i32* %ptr, i32 %value monotonic

; CHECK: [[TOPLABEL1:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync s{{[0-9]+}}, (s0)
; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
; CHECK: add_i s{{[0-9]+}}, s{{[0-9]+}}, s1
; CHECK: store_sync s{{[0-9]+}}, (s0)	
; CHECK: bfalse s{{[0-9]+}}, [[TOPLABEL1]]


	ret i32 %tmp
}

; Note constant operand.  This will use an immediate instruction form.
define i32 @atomic_add_imm(i32* %ptr) { ; CHECK: atomic_add_imm:
	%tmp = atomicrmw volatile add i32* %ptr, i32 13 monotonic

; CHECK: [[TOPLABEL2:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync s{{[0-9]+}}, (s0)
; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
; CHECK: add_i s{{[0-9]+}}, s{{[0-9]+}}, 13
; CHECK: store_sync s{{[0-9]+}}, (s0)	
; CHECK: bfalse s{{[0-9]+}}, [[TOPLABEL2]]

	ret i32 %tmp
}

; This one has an constant operand, but it doesn't fit in an immediate instruction,
; so this should load the addend from the constant pool

define i32 @atomic_add_large_imm(i32* %ptr) { ; CHECK: atomic_add_large_imm:
	%tmp = atomicrmw volatile add i32* %ptr, i32 1300000 monotonic

; CHECK: load_32 [[CONSTREG1:s[0-9]+]], .LCPI
; CHECK: [[TOPLABEL3:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync s{{[0-9]+}}, (s0)
; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
; CHECK: add_i s{{[0-9]+}}, s{{[0-9]+}}, [[CONSTREG1]]
; CHECK: store_sync s{{[0-9]+}}, (s0)	
; CHECK: bfalse s{{[0-9]+}}, [[TOPLABEL3]]

	ret i32 %tmp
}

define i32 @atomic_sub_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_sub_reg:
	%tmp = atomicrmw volatile sub i32* %ptr, i32 %value monotonic

; CHECK: sub_i s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_sub_imm(i32* %ptr) { ; CHECK: atomic_sub_imm:
	%tmp = atomicrmw volatile sub i32* %ptr, i32 13 monotonic

; CHECK: sub_i s{{[0-9]+}}, s{{[0-9]+}}, 13

	ret i32 %tmp
}

define i32 @atomic_sub_large_imm(i32* %ptr) { ; CHECK: atomic_sub_large_imm:
	%tmp = atomicrmw volatile sub i32* %ptr, i32 1300000 monotonic

; CHECK: load_32 [[CONSTREG2:s[0-9]+]], .LCPI
; CHECK: sub_i s{{[0-9]+}}, s{{[0-9]+}}, [[CONSTREG2]]

	ret i32 %tmp
}

define i32 @atomic_and_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_and_reg:
	%tmp = atomicrmw volatile and i32* %ptr, i32 %value monotonic

; CHECK: and s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_and_imm(i32* %ptr) { ; CHECK: atomic_and_imm:
	%tmp = atomicrmw volatile and i32* %ptr, i32 13 monotonic

; CHECK: and s{{[0-9]+}}, s{{[0-9]+}}, 13

	ret i32 %tmp
}

define i32 @atomic_and_large_imm(i32* %ptr) { ; CHECK: atomic_and_large_imm:
	%tmp = atomicrmw volatile and i32* %ptr, i32 1300000 monotonic

; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
; CHECK: and s{{[0-9]+}}, s{{[0-9]+}}, [[CONST]]

	ret i32 %tmp
}

define i32 @atomic_or_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_or_reg:
	%tmp = atomicrmw volatile or i32* %ptr, i32 %value monotonic

; CHECK: or s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_or_imm(i32* %ptr) { ; CHECK: atomic_or_imm:
	%tmp = atomicrmw volatile or i32* %ptr, i32 13 monotonic

; CHECK: or s{{[0-9]+}}, s{{[0-9]+}}, 13

	ret i32 %tmp
}

define i32 @atomic_or_large_imm(i32* %ptr) { ; CHECK: atomic_or_large_imm:
	%tmp = atomicrmw volatile or i32* %ptr, i32 1300000 monotonic

; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
; CHECK: or s{{[0-9]+}}, s{{[0-9]+}}, [[CONST]]

	ret i32 %tmp
}

define i32 @atomic_xor_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_xor_reg:
	%tmp = atomicrmw volatile xor i32* %ptr, i32 %value monotonic

; CHECK: xor s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_xor_imm(i32* %ptr) { ; CHECK: atomic_xor_imm:
	%tmp = atomicrmw volatile xor i32* %ptr, i32 13 monotonic

; CHECK: xor s{{[0-9]+}}, s{{[0-9]+}}, 13

	ret i32 %tmp
}

define i32 @atomic_xor_large_imm(i32* %ptr) { ; CHECK: atomic_xor_large_imm:
	%tmp = atomicrmw volatile xor i32* %ptr, i32 1300000 monotonic

; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
; CHECK: xor s{{[0-9]+}}, s{{[0-9]+}}, [[CONST]]

	ret i32 %tmp
}

define i32 @atomic_xchg(i32* %ptr, i32 %value) { ; CHECK: atomic_xchg:
	%tmp = atomicrmw volatile xchg i32* %ptr, i32 %value monotonic

; CHECK: load_sync s{{[0-9]+}}, (s0)
; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
; CHECK: store_sync s{{[0-9]+}}, (s0)	
; CHECK: bfalse s{{[0-9]+}}, .L

	ret i32 %tmp
}

define i32 @atomic_cmpxchg(i32* %ptr, i32 %cmp, i32 %newvalue) { ; CHECK: atomic_cmpxchg:
	%tmp = cmpxchg volatile i32* %ptr, i32 %cmp, i32 %newvalue monotonic monotonic

; CHECK: [[LOOP1:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync [[DEST:s[0-9]+]], (s0)
; CHECK: cmpne_i [[CMPRES:s[0-9]+]], [[DEST]], s1
; CHECK: btrue [[CMPRES]], [[EXIT:\.[A-Za-z_0-9]+]]
; CHECK: move [[SUCCESS:s[0-9]+]], s2
; CHECK: store_sync [[SUCCESS]], (s0)	
; CHECK: bfalse [[SUCCESS]], [[LOOP1]]
; CHECK: [[EXIT]]:

	ret i32 %tmp
}