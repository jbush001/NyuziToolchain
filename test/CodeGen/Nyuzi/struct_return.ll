; RUN: llc %s -o - | FileCheck %s
;
; If a function returns a structure, the compiler passes a pointer to it
; (allocated in the caller frame) as the first parameter. Ensure the
; backend treats this parameter specially (it is tagged as an sret type)
;

target triple = "nyuzi-elf-none"


%struct.foo = type { i32, i32 }

; Validate callee

define void @return_struct(%struct.foo* sret %retval, i32 %param1) { ; CHECK-LABEL: return_struct:
  %elem0ptr = getelementptr %struct.foo, %struct.foo* %retval, i32 0, i32 0
  store i32 %param1, i32* %elem0ptr, align 4


  %elem1ptr = getelementptr %struct.foo, %struct.foo* %retval, i32 0, i32 1
  store i32 12, i32* %elem1ptr, align 4


  ; LLVM sometimes reorders these when there are upstream changes to the
  ; optimizer, which is why they use CHECK-DAG
  ; CHECK: store_32 s1, (s0)
  ; CHECK: move s1, 12
  ; CHECK: store_32 s1, 4(s0)

  ret void
}

; Validate caller. I call a different function instead of the one above
; so LLVM doesn't inline it.

declare void @another_struct_return(%struct.foo* sret %retval, i32 %param1)

define void @call_return_struct() { ; CHECK-LABEL: call_return_struct:
  %tmp = alloca %struct.foo, align 4
  call void @another_struct_return(%struct.foo* sret %tmp, i32 2)

  ; CHECK: lea s0, 48(sp)
  ; CHECK: move s1, 2
  ; CHECK: call another_struct_return

  ret void
}

