; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

%class.Foo = type { i32 (...)** }

define void @_Z3barP3Foo(%class.Foo* %f) {
entry:
	%f.addr = alloca %class.Foo*, align 4
	store %class.Foo* %f, %class.Foo** %f.addr, align 4
	%0 = load %class.Foo*, %class.Foo** %f.addr, align 4
	%1 = bitcast %class.Foo* %0 to void (%class.Foo*, i32)***
	%vtable = load void (%class.Foo*, i32)**, void (%class.Foo*, i32)*** %1
	%vfn = getelementptr inbounds void (%class.Foo*, i32)*, void (%class.Foo*, i32)** %vtable, i64 0
	%2 = load void (%class.Foo*, i32)*, void (%class.Foo*, i32)** %vfn
	call void %2(%class.Foo* %0, i32 10)
	
	; CHECK: call s{{[0-9]+}}

	ret void
}
