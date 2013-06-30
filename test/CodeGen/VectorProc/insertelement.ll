; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @inserti(<16 x i32> %orig, i32 %value, i32 %lane) {	; CHECK: inserti
    %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane
    
    ; This should create a mask (which is 1 << lane) and then 
    ; do a predicated store of the value into it.
    
    ; CHECK: [[ONE:s[0-9]+]] = 1
    ; CHECK: [[MASK:s[0-9]+]] = [[ONE]] << s1
    ; CHECK: v{{[0-9]+}}{[[MASK]]} = s0

	ret <16 x i32> %result
}

define <16 x float> @insertf(<16 x float> %orig, float %value, i32 %lane) { ; CHECK: insertf
    %result = insertelement <16 x float> %orig, float %value, i32 %lane
    
    ; This should create a mask (which is 1 << lane) and then 
    ; do a predicated store of the value into it.
    
    ; CHECK: [[ONE:s[0-9]+]] = 1
    ; CHECK: [[MASK:s[0-9]+]] = [[ONE]] << s1
    ; CHECK: vf{{[0-9]+}}{[[MASK]]} = f0

	ret <16 x float> %result
}

