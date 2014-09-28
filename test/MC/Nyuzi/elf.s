; RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | \
; RUN: llvm-objdump -section-headers -t - | FileCheck  %s

_start:  add_i s1, s2, s3 
    
aloop:	goto aloop

; CHECK: SYMBOL TABLE:
; CHECK: 00000004         .text	00000000 aloop
