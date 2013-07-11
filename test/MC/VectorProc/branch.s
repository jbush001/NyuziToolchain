# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
	
foo:	btrue s12, foo	# CHECK: encoding: [0xcc,0xff,0xff,0xf4]