; RUN: llc %s -o - | FileCheck %s -check-prefix=CHECK-STATIC
; RUN: llc -relocation-model=pic %s -o - | FileCheck %s -check-prefix=CHECK-PIC
;
; Test block address
;

target triple = "nyuzi-elf-none"

@glob = common global i8* null, align 4

define void @test_blockaddress() {
  store i8* blockaddress(@test_blockaddress, %label2), i8** @glob, align 4
  br label %label2

	; CHECK-STATIC: movehi [[REG:s[0-9]+]], hi(.Ltmp0)
	; CHECK-STATIC: or [[REG]], [[REG]], lo(.Ltmp0)
	; CHECK-STATIC: .Ltmp0:

	; CHECK-PIC: load_32 s1, got(.Ltmp0)(gp)
	; CHECK-PIC: .Ltmp0:

label2:
  ret void
}

