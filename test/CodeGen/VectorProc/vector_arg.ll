; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; Test passing vector arguments.  The first 5 arguments are in registers
; subsequent arguments must be pushed on the stack.

define <16 x i32> @somefunc(i32 %a, <16 x i32> %b, <16 x i32> %c, <16 x i32> %d, 
	<16 x i32> %e, <16 x i32> %f, <16 x i32> %g, <16 x i32> %h) #0 {

	%result = alloca <16 x i32>
	
	%1 = add <16 x i32> %b, %c ; CHECK: [[RES1:v[0-9]+]] = v0 + v1
	%2 = add <16 x i32> %1, %d ; CHECK: [[RES2:v[0-9]+]] = [[RES1]] + v2
	%3 = add <16 x i32> %2, %e ; CHECK: [[RES3:v[0-9]+]] = [[RES2]] + v3
	%4 = add <16 x i32> %3, %f ; CHECK: [[RES4:v[0-9]+]] = [[RES3]] + v4
	%5 = add <16 x i32> %4, %g ; CHECK: [[RES5:v[0-9]+]] = [[RES4]] + v5
	; CHECK: [[SRC:v[0-9]+]] = mem_l[s29]
	%6 = add <16 x i32> %5, %h	; CHECK: v{{[0-9]+}} = [[RES5]] + [[SRC]]

	ret <16 x i32> %6
}

define <16 x i32> @main() #1 {
	%1 = alloca i32
	%2 = alloca <16 x i32>
	%3 = alloca <16 x i32>
	%4 = alloca <16 x i32>
	%5 = alloca <16 x i32>
	%6 = alloca <16 x i32>
	%7 = alloca <16 x i32>
	%8 = alloca <16 x i32>
	%a = load i32* %1
	%b = load <16 x i32>* %2
	%c = load <16 x i32>* %3
	%d = load <16 x i32>* %4
	%e = load <16 x i32>* %5
	%f = load <16 x i32>* %6
	%g = load <16 x i32>* %7
	%h = load <16 x i32>* %8

	; CHECK: s29 = s29 + -64	
	; CHECK: mem_l[s29] = v{{[0-9]+}}
	%result = call <16 x i32> @somefunc(i32 %a, <16 x i32> %b, <16 x i32> %c, 
		<16 x i32> %d, <16 x i32> %e, <16 x i32> %f, <16 x i32> %g,
		<16 x i32> %h)	; CHECK: call somefunc
		
	; CHECK s29 = s29 + 64
  	ret <16 x i32> %result
}


