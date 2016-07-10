; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

define i32 @atomic_add_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_add_reg:
  %tmp = atomicrmw volatile add i32* %ptr, i32 %value monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move s{{[0-9]+}}, [[OLDVAL]]
  ; CHECK: add_i [[NEWVAL:s[0-9]+]], [[OLDVAL]], s1
  ; CHECK: store_sync [[NEWVAL]], (s0)
  ; CHECK: bfalse [[NEWVAL]],

  ret i32 %tmp
}

; Note constant operand.  This will use an immediate instruction form.
define i32 @atomic_add_imm(i32* %ptr) { ; CHECK: atomic_add_imm:
  %tmp = atomicrmw volatile add i32* %ptr, i32 13 monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move s{{[0-9]+}}, [[OLDVAL]]
  ; CHECK: add_i [[NEWVAL:s[0-9]+]], [[OLDVAL]], 13
  ; CHECK: store_sync [[NEWVAL]], (s0)
  ; CHECK: bfalse [[NEWVAL]],

  ret i32 %tmp
}

; This one has an constant operand, but it doesn't fit in an immediate instruction,
; so this should load the addend from the constant pool

define i32 @atomic_add_large_imm(i32* %ptr) { ; CHECK: atomic_add_large_imm:
  %tmp = atomicrmw volatile add i32* %ptr, i32 1300000 monotonic

  ; CHECK: load_32 [[CONSTREG1:s[0-9]+]], .LCPI
  ; CHECK: load_sync s{{[0-9]+}}, (s0)
  ; CHECK: move s{{[0-9]+}}, s{{[0-9]+}}
  ; CHECK: add_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, [[CONSTREG1]]
  ; CHECK: store_sync [[NEWVAL]], (s0)
  ; CHECK: bfalse [[NEWVAL]],

  ret i32 %tmp
}

define i32 @atomic_sub_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_sub_reg:
  %tmp = atomicrmw volatile sub i32* %ptr, i32 %value monotonic

  ; CHECK: sub_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_sub_imm(i32* %ptr) { ; CHECK: atomic_sub_imm:
  %tmp = atomicrmw volatile sub i32* %ptr, i32 13 monotonic

  ; CHECK: sub_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_sub_large_imm(i32* %ptr) { ; CHECK: atomic_sub_large_imm:
  %tmp = atomicrmw volatile sub i32* %ptr, i32 1300000 monotonic

  ; CHECK: load_32 [[CONSTREG2:s[0-9]+]], .LCPI
  ; CHECK: sub_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, [[CONSTREG2]]
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_and_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_and_reg:
  %tmp = atomicrmw volatile and i32* %ptr, i32 %value monotonic

  ; CHECK: and [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_and_imm(i32* %ptr) { ; CHECK: atomic_and_imm:
  %tmp = atomicrmw volatile and i32* %ptr, i32 13 monotonic

  ; CHECK: and [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_and_large_imm(i32* %ptr) { ; CHECK: atomic_and_large_imm:
  %tmp = atomicrmw volatile and i32* %ptr, i32 1300000 monotonic

  ; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
  ; CHECK: and [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, [[CONST]]
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_or_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_or_reg:
  %tmp = atomicrmw volatile or i32* %ptr, i32 %value monotonic

  ; CHECK: or [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_or_imm(i32* %ptr) { ; CHECK: atomic_or_imm:
  %tmp = atomicrmw volatile or i32* %ptr, i32 13 monotonic

  ; CHECK: or [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_or_large_imm(i32* %ptr) { ; CHECK: atomic_or_large_imm:
  %tmp = atomicrmw volatile or i32* %ptr, i32 1300000 monotonic

  ; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
  ; CHECK: or [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, [[CONST]]
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xor_reg(i32* %ptr, i32 %value) { ; CHECK: atomic_xor_reg:
  %tmp = atomicrmw volatile xor i32* %ptr, i32 %value monotonic

  ; CHECK: xor [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xor_imm(i32* %ptr) { ; CHECK: atomic_xor_imm:
  %tmp = atomicrmw volatile xor i32* %ptr, i32 13 monotonic

  ; CHECK: xor [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xor_large_imm(i32* %ptr) { ; CHECK: atomic_xor_large_imm:
  %tmp = atomicrmw volatile xor i32* %ptr, i32 1300000 monotonic

  ; CHECK: load_32 [[CONST:s[0-9]+]], .LCPI
  ; CHECK: xor [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, [[CONST]]
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xchg(i32* %ptr, i32 %value) { ; CHECK: atomic_xchg:
  %tmp = atomicrmw volatile xchg i32* %ptr, i32 %value monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move s{{[0-9]+}}, [[OLDVAL]]
  ; CHECK: store_sync [[OLDVAL]], (s0)
  ; CHECK: bfalse [[OLDVAL]],

  ret i32 %tmp
}

define { i32, i1 } @atomic_cmpxchg(i32* %ptr, i32 %cmp, i32 %newvalue) { ; CHECK: atomic_cmpxchg:
  %tmp = cmpxchg volatile i32* %ptr, i32 %cmp, i32 %newvalue monotonic monotonic

  ; CHECK: load_sync [[DEST:s[0-9]+]], (
  ; CHECK: cmpne_i [[CMPRES:s[0-9]+]], [[DEST]], s1
  ; CHECK: btrue [[CMPRES]],
  ; CHECK: move [[SUCCESS:s[0-9]+]], s2
  ; CHECK: store_sync [[RESULT:s[0-9]+]], (
  ; CHECK: bfalse [[RESULT]],

  ret { i32, i1 } %tmp
}
