; RUN: llc %s -o - | FileCheck %s
;
; Test that inline assembler constraints are handled correctly
;

target triple = "nyuzi-elf-none"

define void @dflush(i32 %ptr) { ; CHECK-LABEL: dflush:
  call void asm sideeffect "dflush $0", "s" (i32 %ptr)

  ; CHECK: dflush s0

  ret void
}

define <16 x i32> @test_vadd(<16 x i32> %a, i32 %b)  { ; CHECK-LABEL: test_vadd:
  %1 = tail call <16 x i32> asm sideeffect "add $0, $1, $2", "=v,v,s"(<16 x i32> %a, i32 %b)

  ; CHECK: #APP
  ; CHECK: add v0, v0, s0
  ; CHECK: #NO_APP

  ret <16 x i32> %1
}

@sdata = common global i32 0, align 4
@vdata = common global <16 x i32> zeroinitializer, align 64

define void @test_scalar_memory_operand() { ; CHECK-LABEL: test_scalar_memory_operand:
  call i32 asm "load_32 $0, $1", "=s,*m"(i32* @sdata)

  ; CHECK: #APP
  ; CHECK: load_32 s{{[0-9]+}}, (s{{[0-9]+}})
  ; CHECK: #NO_APP

  ret void
}

define void @test_vector_memory_operand() { ; CHECK-LABEL: test_vector_memory_operand:
  call <16 x i32> asm sideeffect "load_v $0, $1", "=v,*m"(<16 x i32>* @vdata)

  ; CHECK: #APP
  ; CHECK: load_v v{{[0-9]+}}, (s{{[0-9]+}})
  ; CHECK: #NO_APP

  ret void
}
