; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @sext8(i8 %v) {				; CHECK: sext8
        %tmp1 = sext i8 %v to i32   	; CHECK: s{{[0-9]+}} = sext8(s{{[0-9]+}})
        ret i32 %tmp1
}

define i32 @zext8(i8 %v) {				; CHECK: zext8
        %tmp1 = zext i8 %v to i32		; CHECK: s{{[0-9]+}} = s{{[0-9]+}} & 255
        ret i32 %tmp1
}

define i32 @sext16(i16 %v) {			; CHECK: sext16
        %tmp1 = sext i16 %v to i32   	; CHECK: s{{[0-9]+}} = sext16(s{{[0-9]+}})
        ret i32 %tmp1
}

define i32 @zext16(i16 %v) {			; CHECK: zext16
        %tmp1 = zext i16 %v to i32		; s{{[0-9]+}} = s{{[0-9]+}} & s{{[0-9]+}}
        ret i32 %tmp1
}



