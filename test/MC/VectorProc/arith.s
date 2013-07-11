# RUN: llvm-mc -arch=vectorproc -show-inst %s | FileCheck %s

    add.i s1, s2, s3
# CHECK: <MCInst #{{[0-9]+}} 
# CHECK-NEXT: <MCOperand Reg:5>
# CHECK-NEXT: <MCOperand Reg:6>
# CHECK-NEXT: <MCOperand Reg:7>>

	
foo:
	add.i v1, v2, s5
	add.f s1, s2, s3
	add.i s1, s2, 12


	btrue s1, foo