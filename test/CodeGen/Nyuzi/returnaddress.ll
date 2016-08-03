; RUN: llc %s -o - | FileCheck %s
;
; Test __builtin_returnaddress
;

target triple = "nyuzi-elf-none"

declare i8 *@llvm.returnaddress(i32)
declare void @somefunc()

; For this test, we can use the ra register, because there has been no intervening call
define i8* @return_addr1() {
  %1 = call i8* @llvm.returnaddress(i32 0)

  ; CHECK: move s0, ra

  ret i8* %1
}

; If we've made another call, ra will be clobbered and needs to be saved.
define i8* @return_addr2() {
  ; CHECK: move [[SAVEREG:s[0-9]+]], ra

  call void @somefunc()

  ; CHECK: call somefunc

  %1 = call i8* @llvm.returnaddress(i32 0)

  ; CHECK: move s0, [[SAVEREG]]

  ret i8* %1
}
