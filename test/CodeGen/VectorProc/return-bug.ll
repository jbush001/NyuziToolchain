; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define void @_Z9printCharc(i8 signext %c) #0 {
entry:
  ret void
}

define void @_Z8printHexj(i32 %value) #0 {
entry:
  %value.addr = alloca i32, align 4
  %i = alloca i32, align 4
  %digitVal = alloca i32, align 4
  store i32 %value, i32* %value.addr, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32* %i, align 4
  %cmp = icmp slt i32 %0, 8
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32* %value.addr, align 4
  %shr = lshr i32 %1, 28
  store i32 %shr, i32* %digitVal, align 4
  %2 = load i32* %value.addr, align 4
  %shl = shl i32 %2, 4
  store i32 %shl, i32* %value.addr, align 4
  %3 = load i32* %digitVal, align 4
  %cmp1 = icmp sge i32 %3, 10
  br i1 %cmp1, label %if.then, label %if.else

if.then:                                          ; preds = %for.body
  %4 = load i32* %digitVal, align 4
  %sub = sub nsw i32 %4, 10
  %add = add nsw i32 %sub, 97
  %conv = trunc i32 %add to i8
  call void @_Z9printCharc(i8 signext %conv)
  br label %if.end

if.else:                                          ; preds = %for.body
  %5 = load i32* %digitVal, align 4
  %add2 = add nsw i32 %5, 48
  %conv3 = trunc i32 %add2 to i8
  call void @_Z9printCharc(i8 signext %conv3)
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  br label %for.inc

for.inc:                                          ; preds = %if.end
  %6 = load i32* %i, align 4
  %inc = add nsw i32 %6, 1
  store i32 %inc, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  call void @_Z9printCharc(i8 signext 10)
  ret void

; CHECK: move s{{[0-9]+}}, 10
; CHECK: call _Z9printCharc
; CHECK: load.32 link, {{[0-9]+}}(sp)     

}