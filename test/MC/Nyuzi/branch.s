# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s

foo:  b target0    # CHECK: encoding: [A,A,A,0b1111011A]
  # CHECK: fixup A - offset: 0, value: target0, kind: fixup_Nyuzi_Branch25

  bnz s1, target1  # CHECK: encoding: [0bAAA00001,A,A,0b1111010A]
  # CHECK: #   fixup A - offset: 0, value: target1, kind: fixup_Nyuzi_Branch20

  bz s2, target2  # CHECK: encoding: [0bAAA00010,A,A,0b1111001A]
  # CHECK: #   fixup A - offset: 0, value: target2, kind: fixup_Nyuzi_Branch20

  call target5  # CHECK: encoding: [A,A,A,0b1111100A]
  # CHECK: #   fixup A - offset: 0, value: target5, kind: fixup_Nyuzi_Branch25

  b s2  # CHECK: encoding: [0x02,0x00,0x00,0xf0]

  call s3 # CHECK: encoding: [0x63,0x00,0x00,0xfc]

  ret # CHECK: encoding: [0x1f,0x00,0x00,0xf0]

  eret  # CHECK: encoding: [0x00,0x00,0x00,0xfe]

target0: nop
target1: nop
target2: nop
target3: nop
target4: nop
target5: nop
