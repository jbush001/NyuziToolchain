# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

	dflush s7	; CHECK: encoding: [0x07,0x00,0x00,0xe4]