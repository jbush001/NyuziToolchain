; RUN: llc -mtriple nyuzi-elf %s -o - | FileCheck %s

target triple = "nyuzi"

declare i8* @dummy_func()

@glob = common global i8* null, align 4

define void @test_brindirect() {
  %call = tail call i8* @dummy_func()
  indirectbr i8* %call, [label %label1, label %label2]


  ; Ensure we create an indirect goto
  ; CHECK: goto s{{[0-9]+}}

label1:
  store i8* blockaddress(@test_brindirect, %label2), i8** @glob, align 4
  br label %label1

label2:
  store i8* blockaddress(@test_brindirect, %label1), i8** @glob, align 4
  ret void
}
