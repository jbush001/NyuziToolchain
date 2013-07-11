# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

    add.i s1, s2, s3 # CHECK: # encoding: [0x00,0x00,0x00,0x00]
	
foo:
	add.i v1, v2, s5
	add.f s1, s2, s3
	add.i s1, s2, 12

	and s1, s1, s2
	
	btrue s1, foo