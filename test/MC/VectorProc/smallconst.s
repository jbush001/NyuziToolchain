# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s

move s1, 72		; CHECK: encoding: [0x21,0x20,0x81,0x07]
