# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
	
foo:
	load.32 s1, 12(s2)	
	load.32 s3, (s4)
	load.32 s4, foo	
