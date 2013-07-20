; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @fib(i32 %a) #0 {	; CHECK: fib:
entry:
	; CHECK: sub.i sp, sp, 64

  %cmp = icmp sge i32 %a, 2				
  br i1 %cmp, label %if.then, label %return

if.then: 
  %sub = sub nsw i32 %a, 1				; CHECK: add.i s0, s{{[0-9]+}}, -1
  %call = call i32 @fib(i32 %sub)		; CHECK: call fib
  
  ; CHECK: move s{{[0-9]+}}, s0
  
  %sub1 = sub nsw i32 %a, 2				; CHECK: add.i s0, s{{[0-9]+}}, -2
  %call2 = call i32 @fib(i32 %sub1)		; CHECK: call fib


  %sum = add nsw i32 %call, %call2		
  br label %return

return: 
  %0 = phi i32 [ %sum, %if.then ], [ %a, %entry ]

	; CHECK: add.i sp, sp, 64
	; CHECK: ret
	
  ret i32 %0
}
