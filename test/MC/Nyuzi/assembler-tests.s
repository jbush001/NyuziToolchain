# This file auto-generated by make_tests.py. Do not edit.
# RUN: llvm-mc -arch=nyuzi -show-encoding %s | FileCheck %s
or s1, s2, s3 # CHECK: 0x22,0x80,0x01,0xc0
or v5, v6, s7 # CHECK: 0xa6,0x80,0x03,0xc4
or_mask v9, s12, v10, s11 # CHECK: 0x2a,0xb1,0x05,0xc8
or v13, v14, v15 # CHECK: 0xae,0x81,0x07,0xd0
or_mask v17, s20, v18, v19 # CHECK: 0x32,0xd2,0x09,0xd4
or s21, s22, 110 # CHECK: 0xb6,0xba,0x01,0x00
or v24, v25, 30 # CHECK: 0x19,0x7b,0x00,0x10
or_mask v27, s1, v0, -1 # CHECK: 0x60,0x87,0x7f,0x20
or v2, s3, 91 # CHECK: 0x43,0x6c,0x01,0x40
or_mask v5, s7, s6, 65 # CHECK: 0xa6,0x9c,0x20,0x50
and s8, s9, s10 # CHECK: 0x09,0x01,0x15,0xc0
and v12, v13, s14 # CHECK: 0x8d,0x01,0x17,0xc4
and_mask v16, s19, v17, s18 # CHECK: 0x11,0x4e,0x19,0xc8
and v20, v21, v22 # CHECK: 0x95,0x02,0x1b,0xd0
and_mask v24, s27, v25, v26 # CHECK: 0x19,0x6f,0x1d,0xd4
and s0, s1, -77 # CHECK: 0x01,0xcc,0xfe,0x00
and v3, v4, 81 # CHECK: 0x64,0x44,0x81,0x10
and_mask v6, s8, v7, 70 # CHECK: 0xc7,0x20,0xa3,0x20
and v9, s10, 56 # CHECK: 0x2a,0xe1,0x80,0x40
and_mask v12, s14, s13, 1 # CHECK: 0x8d,0xb9,0x80,0x50
xor s15, s16, s17 # CHECK: 0xf0,0x81,0x38,0xc0
xor v19, v20, s21 # CHECK: 0x74,0x82,0x3a,0xc4
xor_mask v23, s26, v24, s25 # CHECK: 0xf8,0xea,0x3c,0xc8
xor v27, v0, v1 # CHECK: 0x60,0x83,0x30,0xd0
xor_mask v3, s6, v4, v5 # CHECK: 0x64,0x98,0x32,0xd4
xor s7, s8, -91 # CHECK: 0xe8,0x94,0xfe,0x01
xor v10, v11, -49 # CHECK: 0x4b,0x3d,0xff,0x11
xor_mask v13, s15, v14, 89 # CHECK: 0xae,0xbd,0xac,0x21
xor v16, s17, 59 # CHECK: 0x11,0xee,0x80,0x41
xor_mask v19, s21, s20, 53 # CHECK: 0x74,0xd6,0x9a,0x51
add_i s22, s23, s24 # CHECK: 0xd7,0x02,0x5c,0xc0
add_i v26, v27, s0 # CHECK: 0x5b,0x03,0x50,0xc4
add_i_mask v2, s5, v3, s4 # CHECK: 0x43,0x14,0x52,0xc8
add_i v6, v7, v8 # CHECK: 0xc7,0x00,0x54,0xd0
add_i_mask v10, s13, v11, v12 # CHECK: 0x4b,0x35,0x56,0xd4
add_i s14, s15, 96 # CHECK: 0xcf,0x81,0x81,0x02
add_i v17, v18, -20 # CHECK: 0x32,0xb2,0xff,0x12
add_i_mask v20, s22, v21, 113 # CHECK: 0x95,0xda,0xb8,0x22
add_i v23, s24, 48 # CHECK: 0xf8,0xc2,0x80,0x42
add_i_mask v26, s0, s27, 89 # CHECK: 0x5b,0x83,0xac,0x52
sub_i s1, s2, s3 # CHECK: 0x22,0x80,0x61,0xc0
sub_i v5, v6, s7 # CHECK: 0xa6,0x80,0x63,0xc4
sub_i_mask v9, s12, v10, s11 # CHECK: 0x2a,0xb1,0x65,0xc8
sub_i v13, v14, v15 # CHECK: 0xae,0x81,0x67,0xd0
sub_i_mask v17, s20, v18, v19 # CHECK: 0x32,0xd2,0x69,0xd4
sub_i s21, s22, 27 # CHECK: 0xb6,0x6e,0x00,0x03
sub_i v24, v25, -69 # CHECK: 0x19,0xef,0x7e,0x13
sub_i_mask v27, s1, v0, -77 # CHECK: 0x60,0x87,0x59,0x23
sub_i v2, s3, 6 # CHECK: 0x43,0x18,0x00,0x43
sub_i_mask v5, s7, s6, 20 # CHECK: 0xa6,0x1c,0x0a,0x53
mull_i s8, s9, s10 # CHECK: 0x09,0x01,0x75,0xc0
mull_i v12, v13, s14 # CHECK: 0x8d,0x01,0x77,0xc4
mull_i_mask v16, s19, v17, s18 # CHECK: 0x11,0x4e,0x79,0xc8
mull_i v20, v21, v22 # CHECK: 0x95,0x02,0x7b,0xd0
mull_i_mask v24, s27, v25, v26 # CHECK: 0x19,0x6f,0x7d,0xd4
mull_i s0, s1, 103 # CHECK: 0x01,0x9c,0x81,0x03
mull_i v3, v4, -7 # CHECK: 0x64,0xe4,0xff,0x13
mull_i_mask v6, s8, v7, 60 # CHECK: 0xc7,0x20,0x9e,0x23
mull_i v9, s10, -13 # CHECK: 0x2a,0xcd,0xff,0x43
mull_i_mask v12, s14, s13, 77 # CHECK: 0x8d,0xb9,0xa6,0x53
mulhu_i s15, s16, s17 # CHECK: 0xf0,0x81,0x88,0xc0
mulhu_i v19, v20, s21 # CHECK: 0x74,0x82,0x8a,0xc4
mulhu_i_mask v23, s26, v24, s25 # CHECK: 0xf8,0xea,0x8c,0xc8
mulhu_i v27, v0, v1 # CHECK: 0x60,0x83,0x80,0xd0
mulhu_i_mask v3, s6, v4, v5 # CHECK: 0x64,0x98,0x82,0xd4
mulhu_i s7, s8, -48 # CHECK: 0xe8,0x40,0x7f,0x04
mulhu_i v10, v11, 40 # CHECK: 0x4b,0xa1,0x00,0x14
mulhu_i_mask v13, s15, v14, 67 # CHECK: 0xae,0xbd,0x21,0x24
mulhu_i v16, s17, -101 # CHECK: 0x11,0x6e,0x7e,0x44
mulhu_i_mask v19, s21, s20, -94 # CHECK: 0x74,0x56,0x51,0x54
ashr s22, s23, s24 # CHECK: 0xd7,0x02,0x9c,0xc0
ashr v26, v27, s0 # CHECK: 0x5b,0x03,0x90,0xc4
ashr_mask v2, s5, v3, s4 # CHECK: 0x43,0x14,0x92,0xc8
ashr v6, v7, v8 # CHECK: 0xc7,0x00,0x94,0xd0
ashr_mask v10, s13, v11, v12 # CHECK: 0x4b,0x35,0x96,0xd4
ashr s14, s15, 92 # CHECK: 0xcf,0x71,0x81,0x04
ashr v17, v18, 101 # CHECK: 0x32,0x96,0x81,0x14
ashr_mask v20, s22, v21, -86 # CHECK: 0x95,0x5a,0xd5,0x24
ashr v23, s24, 65 # CHECK: 0xf8,0x06,0x81,0x44
ashr_mask v26, s0, s27, 68 # CHECK: 0x5b,0x03,0xa2,0x54
shr s1, s2, s3 # CHECK: 0x22,0x80,0xa1,0xc0
shr v5, v6, s7 # CHECK: 0xa6,0x80,0xa3,0xc4
shr_mask v9, s12, v10, s11 # CHECK: 0x2a,0xb1,0xa5,0xc8
shr v13, v14, v15 # CHECK: 0xae,0x81,0xa7,0xd0
shr_mask v17, s20, v18, v19 # CHECK: 0x32,0xd2,0xa9,0xd4
shr s21, s22, -101 # CHECK: 0xb6,0x6e,0x7e,0x05
shr v24, v25, 68 # CHECK: 0x19,0x13,0x01,0x15
shr_mask v27, s1, v0, -110 # CHECK: 0x60,0x07,0x49,0x25
shr v2, s3, 91 # CHECK: 0x43,0x6c,0x01,0x45
shr_mask v5, s7, s6, -4 # CHECK: 0xa6,0x1c,0x7e,0x55
shl s8, s9, s10 # CHECK: 0x09,0x01,0xb5,0xc0
shl v12, v13, s14 # CHECK: 0x8d,0x01,0xb7,0xc4
shl_mask v16, s19, v17, s18 # CHECK: 0x11,0x4e,0xb9,0xc8
shl v20, v21, v22 # CHECK: 0x95,0x02,0xbb,0xd0
shl_mask v24, s27, v25, v26 # CHECK: 0x19,0x6f,0xbd,0xd4
shl s0, s1, 4 # CHECK: 0x01,0x10,0x80,0x05
shl v3, v4, 34 # CHECK: 0x64,0x88,0x80,0x15
shl_mask v6, s8, v7, 117 # CHECK: 0xc7,0xa0,0xba,0x25
shl v9, s10, -116 # CHECK: 0x2a,0x31,0xfe,0x45
shl_mask v12, s14, s13, -40 # CHECK: 0x8d,0x39,0xec,0x55
add_f s15, s16, s17 # CHECK: 0xf0,0x81,0x08,0xc2
add_f v19, v20, s21 # CHECK: 0x74,0x82,0x0a,0xc6
add_f_mask v23, s26, v24, s25 # CHECK: 0xf8,0xea,0x0c,0xca
add_f v27, v0, v1 # CHECK: 0x60,0x83,0x00,0xd2
add_f_mask v3, s6, v4, v5 # CHECK: 0x64,0x98,0x02,0xd6
sub_f s7, s8, s9 # CHECK: 0xe8,0x80,0x14,0xc2
sub_f v11, v12, s13 # CHECK: 0x6c,0x81,0x16,0xc6
sub_f_mask v15, s18, v16, s17 # CHECK: 0xf0,0xc9,0x18,0xca
sub_f v19, v20, v21 # CHECK: 0x74,0x82,0x1a,0xd2
sub_f_mask v23, s26, v24, v25 # CHECK: 0xf8,0xea,0x1c,0xd6
mul_f s27, s0, s1 # CHECK: 0x60,0x83,0x20,0xc2
mul_f v3, v4, s5 # CHECK: 0x64,0x80,0x22,0xc6
mul_f_mask v7, s10, v8, s9 # CHECK: 0xe8,0xa8,0x24,0xca
mul_f v11, v12, v13 # CHECK: 0x6c,0x81,0x26,0xd2
mul_f_mask v15, s18, v16, v17 # CHECK: 0xf0,0xc9,0x28,0xd6
mulhs_i s19, s20, s21 # CHECK: 0x74,0x82,0xfa,0xc1
mulhs_i v23, v24, s25 # CHECK: 0xf8,0x82,0xfc,0xc5
mulhs_i_mask v27, s2, v0, s1 # CHECK: 0x60,0x8b,0xf0,0xc9
mulhs_i v3, v4, v5 # CHECK: 0x64,0x80,0xf2,0xd1
mulhs_i_mask v7, s10, v8, v9 # CHECK: 0xe8,0xa8,0xf4,0xd5
mulhs_i s11, s12, 8 # CHECK: 0x6c,0x21,0x80,0x0f
mulhs_i v14, v15, -124 # CHECK: 0xcf,0x11,0xfe,0x1f
mulhs_i_mask v17, s19, v18, -14 # CHECK: 0x32,0x4e,0xf9,0x2f
mulhs_i v20, s21, -109 # CHECK: 0x95,0x4e,0xfe,0x4f
mulhs_i_mask v23, s25, s24, 47 # CHECK: 0xf8,0xe6,0x97,0x5f
clz s1, s2 # CHECK: 0x20,0x00,0xc1,0xc0
clz v1, s2 # CHECK: 0x20,0x00,0xc1,0xc4
clz_mask v1, s3, s2 # CHECK: 0x20,0x0c,0xc1,0xc8
clz v1, v2 # CHECK: 0x20,0x00,0xc1,0xd0
clz_mask v1, s3, v2 # CHECK: 0x20,0x0c,0xc1,0xd4
ctz s4, s5 # CHECK: 0x80,0x80,0xe2,0xc0
ctz v4, s5 # CHECK: 0x80,0x80,0xe2,0xc4
ctz_mask v4, s6, s5 # CHECK: 0x80,0x98,0xe2,0xc8
ctz v4, v5 # CHECK: 0x80,0x80,0xe2,0xd0
ctz_mask v4, s6, v5 # CHECK: 0x80,0x98,0xe2,0xd4
move s7, s8 # CHECK: 0xe0,0x00,0xf4,0xc0
move v7, s8 # CHECK: 0xe0,0x00,0xf4,0xc4
move_mask v7, s9, s8 # CHECK: 0xe0,0x24,0xf4,0xc8
move v7, v8 # CHECK: 0xe0,0x00,0xf4,0xd0
move_mask v7, s9, v8 # CHECK: 0xe0,0x24,0xf4,0xd4
reciprocal s10, s11 # CHECK: 0x40,0x81,0xc5,0xc1
reciprocal v10, s11 # CHECK: 0x40,0x81,0xc5,0xc5
reciprocal_mask v10, s12, s11 # CHECK: 0x40,0xb1,0xc5,0xc9
reciprocal v10, v11 # CHECK: 0x40,0x81,0xc5,0xd1
reciprocal_mask v10, s12, v11 # CHECK: 0x40,0xb1,0xc5,0xd5
move s1, 72 # CHECK: 0x21,0x20,0x81,0x07
move v1, 72 # CHECK: 0x21,0x20,0x81,0x47
move_mask v1, s3, 72 # CHECK: 0x21,0x0c,0xa4,0x57
shuffle v1, v2, v3 # CHECK: 0x22,0x80,0xd1,0xd0
shuffle_mask v1, s4, v2, v3 # CHECK: 0x22,0x90,0xd1,0xd4
getlane s4, v5, s6 # CHECK: 0x85,0x00,0xa3,0xc5
getlane s4, v5, 7 # CHECK: 0x85,0x1c,0x00,0x1d
sext_8 s8, s9 # CHECK: 0x00,0x81,0xd4,0xc1
sext_16 s8, s9 # CHECK: 0x00,0x81,0xe4,0xc1
itof s8, s9 # CHECK: 0x00,0x81,0xa4,0xc2
ftoi s8, s9 # CHECK: 0x00,0x81,0xb4,0xc1
itof v8, v9 # CHECK: 0x00,0x81,0xa4,0xd2
ftoi v8, v9 # CHECK: 0x00,0x81,0xb4,0xd1
itof v8, s9 # CHECK: 0x00,0x81,0xa4,0xc6
ftoi v8, s9 # CHECK: 0x00,0x81,0xb4,0xc5
nop # CHECK: 0x00,0x00,0x00,0x00
cmpeq_i s1, s2, s3 # CHECK: 0x22,0x80,0x01,0xc1
cmpeq_i s1, v2, s3 # CHECK: 0x22,0x80,0x01,0xc5
cmpeq_i s1, v2, v3 # CHECK: 0x22,0x80,0x01,0xd1
cmpeq_i s1, s2, 215 # CHECK: 0x22,0x5c,0x03,0x08
cmpeq_i s1, v2, 215 # CHECK: 0x22,0x5c,0x03,0x18
cmpne_i s4, s5, s6 # CHECK: 0x85,0x00,0x13,0xc1
cmpne_i s4, v5, s6 # CHECK: 0x85,0x00,0x13,0xc5
cmpne_i s4, v5, v6 # CHECK: 0x85,0x00,0x13,0xd1
cmpne_i s4, s5, 147 # CHECK: 0x85,0x4c,0x82,0x08
cmpne_i s4, v5, 147 # CHECK: 0x85,0x4c,0x82,0x18
cmpgt_i s7, s8, s9 # CHECK: 0xe8,0x80,0x24,0xc1
cmpgt_i s7, v8, s9 # CHECK: 0xe8,0x80,0x24,0xc5
cmpgt_i s7, v8, v9 # CHECK: 0xe8,0x80,0x24,0xd1
cmpgt_i s7, s8, 170 # CHECK: 0xe8,0xa8,0x02,0x09
cmpgt_i s7, v8, 170 # CHECK: 0xe8,0xa8,0x02,0x19
cmpge_i s10, s11, s12 # CHECK: 0x4b,0x01,0x36,0xc1
cmpge_i s10, v11, s12 # CHECK: 0x4b,0x01,0x36,0xc5
cmpge_i s10, v11, v12 # CHECK: 0x4b,0x01,0x36,0xd1
cmpge_i s10, s11, 64 # CHECK: 0x4b,0x01,0x81,0x09
cmpge_i s10, v11, 64 # CHECK: 0x4b,0x01,0x81,0x19
cmplt_i s13, s14, s15 # CHECK: 0xae,0x81,0x47,0xc1
cmplt_i s13, v14, s15 # CHECK: 0xae,0x81,0x47,0xc5
cmplt_i s13, v14, v15 # CHECK: 0xae,0x81,0x47,0xd1
cmplt_i s13, s14, 167 # CHECK: 0xae,0x9d,0x02,0x0a
cmplt_i s13, v14, 167 # CHECK: 0xae,0x9d,0x02,0x1a
cmple_i s16, s17, s18 # CHECK: 0x11,0x02,0x59,0xc1
cmple_i s16, v17, s18 # CHECK: 0x11,0x02,0x59,0xc5
cmple_i s16, v17, v18 # CHECK: 0x11,0x02,0x59,0xd1
cmple_i s16, s17, 64 # CHECK: 0x11,0x02,0x81,0x0a
cmple_i s16, v17, 64 # CHECK: 0x11,0x02,0x81,0x1a
cmpgt_u s19, s20, s21 # CHECK: 0x74,0x82,0x6a,0xc1
cmpgt_u s19, v20, s21 # CHECK: 0x74,0x82,0x6a,0xc5
cmpgt_u s19, v20, v21 # CHECK: 0x74,0x82,0x6a,0xd1
cmpgt_u s19, s20, 175 # CHECK: 0x74,0xbe,0x02,0x0b
cmpgt_u s19, v20, 175 # CHECK: 0x74,0xbe,0x02,0x1b
cmpge_u s22, s23, s24 # CHECK: 0xd7,0x02,0x7c,0xc1
cmpge_u s22, v23, s24 # CHECK: 0xd7,0x02,0x7c,0xc5
cmpge_u s22, v23, v24 # CHECK: 0xd7,0x02,0x7c,0xd1
cmpge_u s22, s23, 141 # CHECK: 0xd7,0x36,0x82,0x0b
cmpge_u s22, v23, 141 # CHECK: 0xd7,0x36,0x82,0x1b
cmplt_u s25, s26, s27 # CHECK: 0x3a,0x83,0x8d,0xc1
cmplt_u s25, v26, s27 # CHECK: 0x3a,0x83,0x8d,0xc5
cmplt_u s25, v26, v27 # CHECK: 0x3a,0x83,0x8d,0xd1
cmplt_u s25, s26, 231 # CHECK: 0x3a,0x9f,0x03,0x0c
cmplt_u s25, v26, 231 # CHECK: 0x3a,0x9f,0x03,0x1c
cmple_u s0, s1, s2 # CHECK: 0x01,0x00,0x91,0xc1
cmple_u s0, v1, s2 # CHECK: 0x01,0x00,0x91,0xc5
cmple_u s0, v1, v2 # CHECK: 0x01,0x00,0x91,0xd1
cmple_u s0, s1, 189 # CHECK: 0x01,0xf4,0x82,0x0c
cmple_u s0, v1, 189 # CHECK: 0x01,0xf4,0x82,0x1c
cmpgt_f s3, s4, s5 # CHECK: 0x64,0x80,0xc2,0xc2
cmpgt_f s3, v4, s5 # CHECK: 0x64,0x80,0xc2,0xc6
cmpgt_f s3, v4, v5 # CHECK: 0x64,0x80,0xc2,0xd2
cmpge_f s6, s7, s8 # CHECK: 0xc7,0x00,0xd4,0xc2
cmpge_f s6, v7, s8 # CHECK: 0xc7,0x00,0xd4,0xc6
cmpge_f s6, v7, v8 # CHECK: 0xc7,0x00,0xd4,0xd2
cmplt_f s9, s10, s11 # CHECK: 0x2a,0x81,0xe5,0xc2
cmplt_f s9, v10, s11 # CHECK: 0x2a,0x81,0xe5,0xc6
cmplt_f s9, v10, v11 # CHECK: 0x2a,0x81,0xe5,0xd2
cmple_f s12, s13, s14 # CHECK: 0x8d,0x01,0xf7,0xc2
cmple_f s12, v13, s14 # CHECK: 0x8d,0x01,0xf7,0xc6
cmple_f s12, v13, v14 # CHECK: 0x8d,0x01,0xf7,0xd2
load_u8 s1, (s2) # CHECK: 0x22,0x00,0x00,0xa0
load_u8 s1, 3(s2) # CHECK: 0x22,0x0c,0x00,0xa0
load_s8 s4, (s5) # CHECK: 0x85,0x00,0x00,0xa2
load_s8 s4, 6(s5) # CHECK: 0x85,0x18,0x00,0xa2
load_u16 s7, (s8) # CHECK: 0xe8,0x00,0x00,0xa4
load_u16 s7, 9(s8) # CHECK: 0xe8,0x24,0x00,0xa4
load_s16 s10, (s11) # CHECK: 0x4b,0x01,0x00,0xa6
load_s16 s10, 12(s11) # CHECK: 0x4b,0x31,0x00,0xa6
load_32 s13, (s14) # CHECK: 0xae,0x01,0x00,0xa8
load_32 s13, 15(s14) # CHECK: 0xae,0x3d,0x00,0xa8
load_sync s16, (s17) # CHECK: 0x11,0x02,0x00,0xaa
load_sync s16, 18(s17) # CHECK: 0x11,0x4a,0x00,0xaa
store_8 s19, (s20) # CHECK: 0x74,0x02,0x00,0x82
store_8 s19, 21(s20) # CHECK: 0x74,0x56,0x00,0x82
store_16 s22, (s23) # CHECK: 0xd7,0x02,0x00,0x86
store_16 s22, 24(s23) # CHECK: 0xd7,0x62,0x00,0x86
store_32 s25, (s26) # CHECK: 0x3a,0x03,0x00,0x88
store_32 s25, 27(s26) # CHECK: 0x3a,0x6f,0x00,0x88
store_sync s0, (s1) # CHECK: 0x01,0x00,0x00,0x8a
store_sync s0, 2(s1) # CHECK: 0x01,0x08,0x00,0x8a
load_v v1, 336(s2) # CHECK: 0x22,0x40,0x05,0xae
load_v_mask v1, s3, 336(s2) # CHECK: 0x22,0x0c,0xa8,0xb0
load_v v1, (s2) # CHECK: 0x22,0x00,0x00,0xae
load_v_mask v1, s3, (s2) # CHECK: 0x22,0x0c,0x00,0xb0
store_v v1, 336(s2) # CHECK: 0x22,0x40,0x05,0x8e
store_v_mask v1, s3, 336(s2) # CHECK: 0x22,0x0c,0xa8,0x90
store_v v1, (s2) # CHECK: 0x22,0x00,0x00,0x8e
store_v_mask v1, s3, (s2) # CHECK: 0x22,0x0c,0x00,0x90
load_gath v4, 296(v5) # CHECK: 0x85,0xa0,0x04,0xba
load_gath_mask v4, s6, 296(v5) # CHECK: 0x85,0x18,0x94,0xbc
load_gath v4, (v5) # CHECK: 0x85,0x00,0x00,0xba
load_gath_mask v4, s6, (v5) # CHECK: 0x85,0x18,0x00,0xbc
store_scat v4, 296(v5) # CHECK: 0x85,0xa0,0x04,0x9a
store_scat_mask v4, s6, 296(v5) # CHECK: 0x85,0x18,0x94,0x9c
store_scat v4, (v5) # CHECK: 0x85,0x00,0x00,0x9a
store_scat_mask v4, s6, (v5) # CHECK: 0x85,0x18,0x00,0x9c
getcr s7, 9 # CHECK: 0xe9,0x00,0x00,0xac
setcr s11, 13 # CHECK: 0x6d,0x01,0x00,0x8c
dflush s7 # CHECK: 0x07,0x00,0x00,0xe4
membar # CHECK: 0x00,0x00,0x00,0xe8
dinvalidate s9 # CHECK: 0x09,0x00,0x00,0xe2
iinvalidate s11 # CHECK: 0x0b,0x00,0x00,0xe6
