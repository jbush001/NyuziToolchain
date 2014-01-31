; RUN: llc %s -o - | FileCheck %s

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

define i32 @atomic_sub_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_sub_reg:
	%tmp = atomicrmw volatile sub i32* %ptr, i32 %value monotonic

; CHECK: sub_i s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_and_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_and_reg:
	%tmp = atomicrmw volatile and i32* %ptr, i32 %value monotonic

; CHECK: and s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_or_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_or_reg:
	%tmp = atomicrmw volatile or i32* %ptr, i32 %value monotonic

; CHECK: or s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_xor_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_xor_reg:
	%tmp = atomicrmw volatile xor i32* %ptr, i32 %value monotonic

; CHECK: xor s{{[0-9]+}}, s{{[0-9]+}}, s1

	ret i32 %tmp
}

define i32 @atomic_xchg(i32* %ptr, i32 %value) { ; CHECK: atomic_xchg:
	%tmp = atomicrmw volatile xchg i32* %ptr, i32 %value monotonic

; CHECK: [[TOPLABEL4:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync s{{[0-9]+}}, (s0)
; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
; CHECK: store_sync s{{[0-9]+}}, (s0)	
; CHECK: bfalse s{{[0-9]+}}, [[TOPLABEL4]]

	ret i32 %tmp
}

define i32 @atomic_cmpxchg(i32* %ptr, i32 %cmp, i32 %newvalue) { ; CHECK: atomic_cmpxchg:
	%tmp = cmpxchg volatile i32* %ptr, i32 %cmp, i32 %newvalue monotonic

; CHECK: [[LOOP1:\.[A-Za-z_0-9]+]]:
; CHECK: load_sync [[DEST:s[0-9]+]], (s0)
; CHECK: setne_i [[CMPRES:s[0-9]+]], [[DEST]], s1
; CHECK: btrue [[CMPRES]], [[EXIT:\.[A-Za-z_0-9]+]]
; CHECK: move [[SUCCESS:s[0-9]+]], s2
; CHECK: store_sync [[SUCCESS]], (s0)	
; CHECK: bfalse [[SUCCESS]], [[LOOP1]]
; CHECK: [[EXIT]]:

	ret i32 %tmp
}
