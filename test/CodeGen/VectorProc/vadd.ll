; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

define i32 @main() #0 {
entry:
  %a = alloca <16 x i32>, align 64
  %b = alloca <16 x i32>, align 64
  %c = alloca <16 x i32>, align 64
  %0 = load <16 x i32>* %b, align 64
  %1 = load <16 x i32>* %c, align 64
  %add = add <16 x i32> %0, %1
  store <16 x i32> %add, <16 x i32>* %a, align 64
  ret i32 0
}

; CHECK: v{{[0-9]+}} = v{{[0-9]+}} + v{{[0-9]+}}
