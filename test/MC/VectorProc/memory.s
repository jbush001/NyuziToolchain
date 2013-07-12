# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
	
foo:
	load.32 s1, (s2) 	# CHECK: encoding: [0x22,0x00,0x00,0xa8]
	load.32 s1, 12(s2)	# CHECK: encoding: [0x22,0x0c,0x00,0xa8]
#	load.32 s4, foo	
