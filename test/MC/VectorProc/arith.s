# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

    add.i s1, s2, s3 # CHECK: encoding: [0x22,0x80,0x51,0xc0]
	
foo:
	sub.i v4, v5, s6 # CHECK: encoding: [0x85,0x00,0x63,0xc4]
	add.f v7, v8, v9 # CHECK: encoding: [0xe8,0x80,0x04,0xd2]
	setgt.f s10, s11, s12 # CHECK: encoding: [0x4b,0x01,0xc6,0xc2]
	and.mask v13, s14, v15, v16 # CHECK: encoding: [0xaf,0x39,0x18,0xd4]

	btrue s1, foo