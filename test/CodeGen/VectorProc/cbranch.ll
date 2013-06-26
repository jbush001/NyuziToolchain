; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; Do a scalar comparison and branch on the result.
define i32 @max(i32 %a, i32 %b) #0 {
entry:
  %cmp = icmp sgt i32 %a, %b
  ; CHECK: s[[CHECKVAL:[0-9]+]] = s{{[0-9]+}} > s{{[0-9]+}}

  br i1 %cmp, label %if.then, label %if.else
  ; CHECK: if s[[CHECKVAL]] goto [[FALSELABEL:[A-Z0-9_]+]]

if.then:
  br label %return
  ; CHECK: goto {{[A-Z0-9_]+}}

if.else:  
  ; CHECK: [[FALSELABEL]]:
  br label %return

return:
  %0 = phi i32 [ %a, %if.then ], [ %b, %if.else ]
  ret i32 %0
}


