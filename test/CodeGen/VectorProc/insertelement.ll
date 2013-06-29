; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @insert(<16 x i32> %orig, i32 %value, i32 %lane) {
    %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane
    
    ; This should create a mask (which is 1 << lane) and then 
    ; do a predicated store of the value into it.
    
    ; CHECK: [[ONE:s[0-9]+]] = 1
    ; CHECK: [[MASK:s[0-9]+]] = [[ONE]] << s0
    ; CHECK: v{{[0-9]+}}{[[MASK]]} = s1

	ret <16 x i32> %result
}

