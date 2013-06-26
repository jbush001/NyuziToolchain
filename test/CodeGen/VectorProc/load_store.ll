; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @loads8(i8* %p) { 		; CHECK: loads8
        %tmp = load i8* %p           
        %tmp1 = sext i8 %tmp to i32  	; CHECK: s{{[0-9+]}} = mem_b[s{{[0-9+]}}]
        ret i32 %tmp1
}

define i32 @loadu8(i8* %p) { 		; CHECK: loadu8
        %tmp = load i8* %p           
        %tmp1 = zext i8 %tmp to i32  	; CHECK: u{{[0-9+]}} = mem_b[s{{[0-9+]}}]
        ret i32 %tmp1
}

define i32 @loads16(i16* %p) { 		; CHECK: loads16
        %tmp = load i16* %p           
        %tmp1 = sext i16 %tmp to i32  	; CHECK: s{{[0-9+]}} = mem_s[s{{[0-9+]}}]
        ret i32 %tmp1
}

define i32 @loadu16(i16* %p) { 		; CHECK: loadu16
        %tmp = load i16* %p     
        %tmp1 = zext i16 %tmp to i32  	; CHECK: u{{[0-9+]}} = mem_s[s{{[0-9+]}}]
        ret i32 %tmp1
}

define i32 @load32(i32* %p) { 		; CHECK: load32
        %tmp = load i32* %p     ; CHECK: s{{[0-9+]}} = mem_l[s{{[0-9+]}}]
        ret i32 %tmp
}

define void @store8(i8* %p, i8 %v) { 		; CHECK: store8
	store i8 %v, i8* %p, align 4		; CHECK: mem_b[s{{[0-9+]}}] = s{{[0-9+]}}
    ret void
}

define void @store16(i16* %p, i16 %v) { 	; CHECK: store16
	store i16 %v, i16* %p, align 4			; CHECK: mem_s[s{{[0-9+]}}] = s{{[0-9+]}}
    ret void
}

define void @store32(i32* %p, i32 %v) { 		; CHECK: store32
	store i32 %v, i32* %p, align 4		; CHECK: mem_l[s{{[0-9+]}}] = s{{[0-9+]}}
    ret void
}

; ADD vector load/store


