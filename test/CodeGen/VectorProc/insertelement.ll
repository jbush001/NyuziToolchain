; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define <16 x i32> @inserti(<16 x i32> %orig, i32 %value, i32 %lane) {	; CHECK: inserti
    %result = insertelement <16 x i32> %orig, i32 %value, i32 %lane
    
    ; This should do a predicated move
    
    ; CHECK: move_mask v{{[0-9]+}}, 

	ret <16 x i32> %result
}

define <16 x float> @insertf(<16 x float> %orig, float %value, i32 %lane) { ; CHECK: insertf
    %result = insertelement <16 x float> %orig, float %value, i32 %lane
    
    ; This should do a predicated move
    
    ; CHECK: move_mask v{{[0-9]+}}, 

	ret <16 x float> %result
}

