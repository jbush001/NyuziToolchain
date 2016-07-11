; RUN: llc %s -o - | FileCheck %s

target triple = "nyuzi-elf-none"

;
; The original bug was that the goto was not inserted at the end of the first block
; when two blocks were tail merged.
;

define i32 @_Z3fibi(i32 %n) {
  %cmp = icmp slt i32 %n, 2
  br i1 %cmp, label %return, label %if.else

  ; CHECK: btrue {{s[0-9]+}}, [[TRUELABEL:[\.A-Z0-9a-z_]+]]

  ; CHECK: [[TRUELABEL]]:
  ; CHECK: goto [[EXITLABEL:[\.A-Z0-9a-z_]+]]

if.else:
  %sub = add nsw i32 %n, -1
  %call = call i32 @_Z3fibi(i32 %sub)
  %sub1 = add nsw i32 %n, -2
  %call2 = call i32 @_Z3fibi(i32 %sub1)

  ; CHECK: call _Z3fibi

  %add = add nsw i32 %call2, %call

  ret i32 %add

  ; CHECK: [[EXITLABEL]]:

return:
  ret i32 %n
}
