; RUN: llc %s -o - | FileCheck %s

target triple = "vectorproc"

; Test passing vector arguments. 

define <16 x i32> @somefunc(i32 %a, <16 x i32> %b, <16 x i32> %c, <16 x i32> %d, 
	<16 x i32> %e, <16 x i32> %f, <16 x i32> %g, <16 x i32> %h) #0 { ; CHECK: somefunc:

	%result = alloca <16 x i32>
	
	%1 = add <16 x i32> %b, %c ; CHECK: add_i [[RES1:v[0-9]+]], v0, v1
	%2 = add <16 x i32> %1, %d ; CHECK: add_i [[RES2:v[0-9]+]], [[RES1]], v2
	%3 = add <16 x i32> %2, %e ; CHECK: add_i [[RES3:v[0-9]+]], [[RES2]], v3
	%4 = add <16 x i32> %3, %f ; CHECK: add_i [[RES4:v[0-9]+]], [[RES3]], v4
	%5 = add <16 x i32> %4, %g ; CHECK: add_i [[RES5:v[0-9]+]], [[RES4]], v5
	%6 = add <16 x i32> %5, %h ; CHECK: add_i [[RES5:v[0-9]+]], [[RES4]], v6
	
	ret <16 x i32> %6
}

define <16 x i32> @main() #1 {	; CHECK: main:
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

	%result = call <16 x i32> @somefunc(i32 %a, <16 x i32> %b, <16 x i32> %c, 
		<16 x i32> %d, <16 x i32> %e, <16 x i32> %f, <16 x i32> %g,
		<16 x i32> %h)	; CHECK: call somefunc
		
  	ret <16 x i32> %result
}


