; RUN: llc %s -o - | FileCheck %s
;
; Virtual function call. This mainly validates calling via a register.
;

target triple = "nyuzi-elf-none"

%class.Foo = type { i32 (...)** }

define void @_Z3barP3Foo(%class.Foo* %f) {
  %f.addr = alloca %class.Foo*, align 4
  store %class.Foo* %f, %class.Foo** %f.addr, align 4
  %1 = load %class.Foo*, %class.Foo** %f.addr, align 4
  %2 = bitcast %class.Foo* %1 to void (%class.Foo*, i32)***
  %vtable = load void (%class.Foo*, i32)**, void (%class.Foo*, i32)*** %2
  %vfn = getelementptr inbounds void (%class.Foo*, i32)*, void (%class.Foo*, i32)** %vtable, i64 0
  %3 = load void (%class.Foo*, i32)*, void (%class.Foo*, i32)** %vfn
  call void %3(%class.Foo* %1, i32 10)

  ; CHECK: call s{{[0-9]+}}

  ret void
}
