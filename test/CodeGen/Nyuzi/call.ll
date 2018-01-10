; RUN: llc %s -o - | FileCheck %s -check-prefix=CHECK-STATIC
; RUN: llc -relocation-model=pic %s -o - | FileCheck %s -check-prefix=CHECK-PIC
;
; Normal function calls, in both position independent and static models.
;


target triple = "nyuzi-none-none"

@gvar = global i32 0, align 4

declare i32 @external_call()

define i32 @internal_call() {
entry:
  %0 = load i32, i32* @gvar, align 4
  ret i32 %0
}

define internal fastcc i32 @static_call() {
entry:
  %0 = load i32, i32* @gvar, align 4
  ret i32 %0
}

define i32 @caller() {
entry:
	; CHECK-STATIC-LABEL: @caller
	; CHECK-PIC-LABEL: @caller

  %call = call i32 @internal_call()

	; CHECK-STATIC: call internal_call

  ; We don't know this is module only, so have to relocate.
	; CHECK-PIC: load_32 s0, got(internal_call)(gp)
	; CHECK-PIC: call s0

  %call1 = call i32 @external_call()

	; CHECK-STATIC: call external_call
	; CHECK-PIC: load_32 s0, got(external_call)(gp)
	; CHECK-PIC: call s0

  %add = add i32 %call1, %call
  %call2 = call i32 @static_call()

	; CHECK-STATIC: call static_call

	; Since this is module only, don't need a GOT relocation for it.
	; CHECK-PIC: call static_call

  %add3 = add i32 %add, %call2
  ret i32 %add3
}
