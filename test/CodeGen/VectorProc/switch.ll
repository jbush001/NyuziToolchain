; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @foo(i32 %i, i32 %j) {
entry:
  switch i32 %i, label %return [
    i32 0, label %sw.bb
    i32 1, label %sw.bb1
    i32 2, label %sw.bb2
    i32 3, label %sw.bb4
  ]

  ; CHECK: lea s{{[0-9]+}}, LJTI  
  ; CHECK: load_32 pc, 

sw.bb: 
  %add = add nsw i32 %j, 1
  br label %return

sw.bb1:
  %mul = mul nsw i32 %j, 7
  br label %return

sw.bb2:
  %mul3 = mul nsw i32 %j, %j
  br label %return

sw.bb4:
  %sub = add nsw i32 %j, -1
  %shl = shl i32 %j, %sub
  br label %return

return:                                           ; preds = %entry, %sw.bb4, %sw.bb2, %sw.bb1, %sw.bb
  %retval.0 = phi i32 [ %shl, %sw.bb4 ], [ %mul3, %sw.bb2 ], [ %mul, %sw.bb1 ], [ %add, %sw.bb ], [ %j, %entry ]
  ret i32 %retval.0
}
