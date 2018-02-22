; RUN: llc %s -o - | FileCheck %s
;
; Test atomic memory operations
;

target triple = "nyuzi-elf-none"

define i32 @atomic_add_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_add_reg:
  %tmp = atomicrmw volatile add i32* %ptr, i32 %value monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move s{{[0-9]+}}, [[OLDVAL]]
  ; CHECK: add_i [[NEWVAL:s[0-9]+]], [[OLDVAL]], s1
  ; CHECK: store_sync [[NEWVAL]], (s0)
  ; CHECK: bz [[NEWVAL]],

  ret i32 %tmp
}

; Constant addend.  This will use an immediate instruction form.
define i32 @atomic_add_imm(i32* %ptr) { ; CHECK-LABEL: atomic_add_imm:
  %tmp = atomicrmw volatile add i32* %ptr, i32 13 monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move s{{[0-9]+}}, [[OLDVAL]]
  ; CHECK: add_i [[NEWVAL:s[0-9]+]], [[OLDVAL]], 13
  ; CHECK: store_sync [[NEWVAL]], (s0)
  ; CHECK: bz [[NEWVAL]],

  ret i32 %tmp
}

define i32 @atomic_sub_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_sub_reg:
  %tmp = atomicrmw volatile sub i32* %ptr, i32 %value monotonic

  ; CHECK: sub_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_sub_imm(i32* %ptr) { ; CHECK-LABEL: atomic_sub_imm:
  %tmp = atomicrmw volatile sub i32* %ptr, i32 13 monotonic

  ; CHECK: sub_i [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_and_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_and_reg:
  %tmp = atomicrmw volatile and i32* %ptr, i32 %value monotonic

  ; CHECK: and [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_and_imm(i32* %ptr) { ; CHECK-LABEL: atomic_and_imm:
  %tmp = atomicrmw volatile and i32* %ptr, i32 13 monotonic

  ; CHECK: and [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_or_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_or_reg:
  %tmp = atomicrmw volatile or i32* %ptr, i32 %value monotonic

  ; CHECK: or [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_or_imm(i32* %ptr) { ; CHECK-LABEL: atomic_or_imm:
  %tmp = atomicrmw volatile or i32* %ptr, i32 13 monotonic

  ; CHECK: or [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xor_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_xor_reg:
  %tmp = atomicrmw volatile xor i32* %ptr, i32 %value monotonic

  ; CHECK: xor [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xor_imm(i32* %ptr) { ; CHECK-LABEL: atomic_xor_imm:
  %tmp = atomicrmw volatile xor i32* %ptr, i32 13 monotonic

  ; CHECK: xor [[NEWVAL:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: store_sync [[NEWVAL]], (s0)

  ret i32 %tmp
}

define i32 @atomic_nand_reg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_nand_reg:
  %tmp = atomicrmw volatile nand i32* %ptr, i32 %value monotonic

  ; CHECK: and [[NEWVAL1:s[0-9]+]], s{{[0-9]+}}, s1
  ; CHECK: xor [[NEWVAL2:s[0-9]+]], [[NEWVAL1]], -1
  ; CHECK: store_sync [[NEWVAL2]], (s0)

  ret i32 %tmp
}

define i32 @atomic_nand_imm(i32* %ptr) { ; CHECK-LABEL: atomic_nand_imm:
  %tmp = atomicrmw volatile nand i32* %ptr, i32 13 monotonic

  ; CHECK: and [[NEWVAL1:s[0-9]+]], s{{[0-9]+}}, 13
  ; CHECK: xor [[NEWVAL2:s[0-9]+]], [[NEWVAL1]], -1
  ; CHECK: store_sync [[NEWVAL2]], (s0)

  ret i32 %tmp
}

define i32 @atomic_xchg(i32* %ptr, i32 %value) { ; CHECK-LABEL: atomic_xchg:
  %tmp = atomicrmw volatile xchg i32* %ptr, i32 %value monotonic

  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move [[TMP:s[0-9]+]], s1
  ; CHECK: store_sync [[TMP]], (s0)
  ; CHECK: bz [[TMP]],
  ; CHECK: move s0, [[OLDVAL]]

  ret i32 %tmp
}

define { i32, i1 } @atomic_cmpxchg(i32* %ptr, i32 %cmp, i32 %newvalue) { ; CHECK-LABEL: atomic_cmpxchg:
  %tmp = cmpxchg volatile i32* %ptr, i32 %cmp, i32 %newvalue monotonic monotonic

  ; CHECK: load_sync [[DEST:s[0-9]+]], (
  ; CHECK: cmpne_i [[CMPRES:s[0-9]+]], [[DEST]], s1
  ; CHECK: bnz [[CMPRES]],
  ; CHECK: move [[SUCCESS:s[0-9]+]], s2
  ; CHECK: store_sync [[RESULT:s[0-9]+]], (
  ; CHECK: bz [[RESULT]],

  ret { i32, i1 } %tmp
}


define void @atomic_store(i32* %lk) { ; CHECK-LABEL: atomic_store:
   store atomic i32 0, i32* %lk release, align 4

  ; This gets expanded to an atomic xchg. It should be optimized to just
  ; do a normal store.
  ; CHECK: load_sync [[OLDVAL:s[0-9]+]], (s0)
  ; CHECK: move [[TMP:s[0-9]+]], s1
  ; CHECK: store_sync [[TMP]], (s0)
  ; CHECK: bz [[TMP]],

   ret void
}
