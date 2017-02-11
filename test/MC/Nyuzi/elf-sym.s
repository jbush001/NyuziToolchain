# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | \
# RUN: llvm-objdump -section-headers -t - | FileCheck  %s

.text
_start:  add_i s1, s2, s3
aloop:	b aloop
bloop:  sub_i s4, s5, s6

.data

foo: .long 0x1234
bar: .long 0x5678

# CHECK: SYMBOL TABLE:
# CHECK-DAG: 00000000         .text	00000000 _start
# CHECK-DAG: 00000004         .text	00000000 aloop
# CHECK-DAG: 00000008         .text	00000000 bloop
# CHECK-DAG: 00000000         .data 00000000 foo
# CHECK-DAG: 00000004         .data 00000000 bar
