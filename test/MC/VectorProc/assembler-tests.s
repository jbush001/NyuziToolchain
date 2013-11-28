# This file auto-generated by make_tests.py. Do not edit.
# RUN: llvm-mc -arch=vectorproc -show-encoding %s | FileCheck %s
or s2, s13, s3  # CHECK: [0x4d,0x80,0x01,0xc0]
or v2, v13, s3  # CHECK: [0x4d,0x80,0x01,0xc4]
or_mask v2, s10, v13, s3  # CHECK: [0x4d,0xa8,0x01,0xc8]
or_invmask v2, s10, v13, s3  # CHECK: [0x4d,0xa8,0x01,0xcc]
or v2, v13, v3  # CHECK: [0x4d,0x80,0x01,0xd0]
or_mask v2, s10, v13, v3  # CHECK: [0x4d,0xa8,0x01,0xd4]
or_invmask v2, s10, v13, v3  # CHECK: [0x4d,0xa8,0x01,0xd8]
or s2, s13, 55  # CHECK: [0x4d,0xdc,0x00,0x00]
or v2, v13, 55  # CHECK: [0x4d,0xdc,0x00,0x10]
or_mask v2, s10, v13, 55  # CHECK: [0x4d,0xa8,0x1b,0x20]
or_invmask v2, s10, v13, 55  # CHECK: [0x4d,0xa8,0x1b,0x30]
or v2, s13, 55  # CHECK: [0x4d,0xdc,0x00,0x40]
or_mask v2, s10, s13, 55  # CHECK: [0x4d,0xa8,0x1b,0x50]
or_invmask v2, s10, s13, 55  # CHECK: [0x4d,0xa8,0x1b,0x60]
and s15, s21, s10  # CHECK: [0xf5,0x01,0x15,0xc0]
and v15, v21, s10  # CHECK: [0xf5,0x01,0x15,0xc4]
and_mask v15, s4, v21, s10  # CHECK: [0xf5,0x11,0x15,0xc8]
and_invmask v15, s4, v21, s10  # CHECK: [0xf5,0x11,0x15,0xcc]
and v15, v21, v10  # CHECK: [0xf5,0x01,0x15,0xd0]
and_mask v15, s4, v21, v10  # CHECK: [0xf5,0x11,0x15,0xd4]
and_invmask v15, s4, v21, v10  # CHECK: [0xf5,0x11,0x15,0xd8]
and s15, s21, 249  # CHECK: [0xf5,0xe5,0x83,0x00]
and v15, v21, 249  # CHECK: [0xf5,0xe5,0x83,0x10]
and_mask v15, s4, v21, 249  # CHECK: [0xf5,0x91,0xfc,0x20]
and_invmask v15, s4, v21, 249  # CHECK: [0xf5,0x91,0xfc,0x30]
and v15, s21, 249  # CHECK: [0xf5,0xe5,0x83,0x40]
and_mask v15, s4, s21, 249  # CHECK: [0xf5,0x91,0xfc,0x50]
and_invmask v15, s4, s21, 249  # CHECK: [0xf5,0x91,0xfc,0x60]
xor s3, s12, s10  # CHECK: [0x6c,0x00,0x35,0xc0]
xor v3, v12, s10  # CHECK: [0x6c,0x00,0x35,0xc4]
xor_mask v3, s18, v12, s10  # CHECK: [0x6c,0x48,0x35,0xc8]
xor_invmask v3, s18, v12, s10  # CHECK: [0x6c,0x48,0x35,0xcc]
xor v3, v12, v10  # CHECK: [0x6c,0x00,0x35,0xd0]
xor_mask v3, s18, v12, v10  # CHECK: [0x6c,0x48,0x35,0xd4]
xor_invmask v3, s18, v12, v10  # CHECK: [0x6c,0x48,0x35,0xd8]
xor s3, s12, 157  # CHECK: [0x6c,0x74,0x82,0x01]
xor v3, v12, 157  # CHECK: [0x6c,0x74,0x82,0x11]
xor_mask v3, s18, v12, 157  # CHECK: [0x6c,0xc8,0xce,0x21]
xor_invmask v3, s18, v12, 157  # CHECK: [0x6c,0xc8,0xce,0x31]
xor v3, s12, 157  # CHECK: [0x6c,0x74,0x82,0x41]
xor_mask v3, s18, s12, 157  # CHECK: [0x6c,0xc8,0xce,0x51]
xor_invmask v3, s18, s12, 157  # CHECK: [0x6c,0xc8,0xce,0x61]
add_i s17, s17, s2  # CHECK: [0x31,0x02,0x51,0xc0]
add_i v17, v17, s2  # CHECK: [0x31,0x02,0x51,0xc4]
add_i_mask v17, s15, v17, s2  # CHECK: [0x31,0x3e,0x51,0xc8]
add_i_invmask v17, s15, v17, s2  # CHECK: [0x31,0x3e,0x51,0xcc]
add_i v17, v17, v2  # CHECK: [0x31,0x02,0x51,0xd0]
add_i_mask v17, s15, v17, v2  # CHECK: [0x31,0x3e,0x51,0xd4]
add_i_invmask v17, s15, v17, v2  # CHECK: [0x31,0x3e,0x51,0xd8]
add_i s17, s17, 41  # CHECK: [0x31,0xa6,0x80,0x02]
add_i v17, v17, 41  # CHECK: [0x31,0xa6,0x80,0x12]
add_i_mask v17, s15, v17, 41  # CHECK: [0x31,0xbe,0x94,0x22]
add_i_invmask v17, s15, v17, 41  # CHECK: [0x31,0xbe,0x94,0x32]
add_i v17, s17, 41  # CHECK: [0x31,0xa6,0x80,0x42]
add_i_mask v17, s15, s17, 41  # CHECK: [0x31,0xbe,0x94,0x52]
add_i_invmask v17, s15, s17, 41  # CHECK: [0x31,0xbe,0x94,0x62]
sub_i s11, s3, s2  # CHECK: [0x63,0x01,0x61,0xc0]
sub_i v11, v3, s2  # CHECK: [0x63,0x01,0x61,0xc4]
sub_i_mask v11, s4, v3, s2  # CHECK: [0x63,0x11,0x61,0xc8]
sub_i_invmask v11, s4, v3, s2  # CHECK: [0x63,0x11,0x61,0xcc]
sub_i v11, v3, v2  # CHECK: [0x63,0x01,0x61,0xd0]
sub_i_mask v11, s4, v3, v2  # CHECK: [0x63,0x11,0x61,0xd4]
sub_i_invmask v11, s4, v3, v2  # CHECK: [0x63,0x11,0x61,0xd8]
sub_i s11, s3, 125  # CHECK: [0x63,0xf5,0x01,0x03]
sub_i v11, v3, 125  # CHECK: [0x63,0xf5,0x01,0x13]
sub_i_mask v11, s4, v3, 125  # CHECK: [0x63,0x91,0x3e,0x23]
sub_i_invmask v11, s4, v3, 125  # CHECK: [0x63,0x91,0x3e,0x33]
sub_i v11, s3, 125  # CHECK: [0x63,0xf5,0x01,0x43]
sub_i_mask v11, s4, s3, 125  # CHECK: [0x63,0x91,0x3e,0x53]
sub_i_invmask v11, s4, s3, 125  # CHECK: [0x63,0x91,0x3e,0x63]
mul_i s12, s25, s21  # CHECK: [0x99,0x81,0x7a,0xc0]
mul_i v12, v25, s21  # CHECK: [0x99,0x81,0x7a,0xc4]
mul_i_mask v12, s6, v25, s21  # CHECK: [0x99,0x99,0x7a,0xc8]
mul_i_invmask v12, s6, v25, s21  # CHECK: [0x99,0x99,0x7a,0xcc]
mul_i v12, v25, v21  # CHECK: [0x99,0x81,0x7a,0xd0]
mul_i_mask v12, s6, v25, v21  # CHECK: [0x99,0x99,0x7a,0xd4]
mul_i_invmask v12, s6, v25, v21  # CHECK: [0x99,0x99,0x7a,0xd8]
mul_i s12, s25, 142  # CHECK: [0x99,0x39,0x82,0x03]
mul_i v12, v25, 142  # CHECK: [0x99,0x39,0x82,0x13]
mul_i_mask v12, s6, v25, 142  # CHECK: [0x99,0x19,0xc7,0x23]
mul_i_invmask v12, s6, v25, 142  # CHECK: [0x99,0x19,0xc7,0x33]
mul_i v12, s25, 142  # CHECK: [0x99,0x39,0x82,0x43]
mul_i_mask v12, s6, s25, 142  # CHECK: [0x99,0x19,0xc7,0x53]
mul_i_invmask v12, s6, s25, 142  # CHECK: [0x99,0x19,0xc7,0x63]
ashr s19, s23, s14  # CHECK: [0x77,0x02,0x97,0xc0]
ashr v19, v23, s14  # CHECK: [0x77,0x02,0x97,0xc4]
ashr_mask v19, s20, v23, s14  # CHECK: [0x77,0x52,0x97,0xc8]
ashr_invmask v19, s20, v23, s14  # CHECK: [0x77,0x52,0x97,0xcc]
ashr v19, v23, v14  # CHECK: [0x77,0x02,0x97,0xd0]
ashr_mask v19, s20, v23, v14  # CHECK: [0x77,0x52,0x97,0xd4]
ashr_invmask v19, s20, v23, v14  # CHECK: [0x77,0x52,0x97,0xd8]
ashr s19, s23, 57  # CHECK: [0x77,0xe6,0x80,0x04]
ashr v19, v23, 57  # CHECK: [0x77,0xe6,0x80,0x14]
ashr_mask v19, s20, v23, 57  # CHECK: [0x77,0xd2,0x9c,0x24]
ashr_invmask v19, s20, v23, 57  # CHECK: [0x77,0xd2,0x9c,0x34]
ashr v19, s23, 57  # CHECK: [0x77,0xe6,0x80,0x44]
ashr_mask v19, s20, s23, 57  # CHECK: [0x77,0xd2,0x9c,0x54]
ashr_invmask v19, s20, s23, 57  # CHECK: [0x77,0xd2,0x9c,0x64]
shr s10, s24, s27  # CHECK: [0x58,0x81,0xad,0xc0]
shr v10, v24, s27  # CHECK: [0x58,0x81,0xad,0xc4]
shr_mask v10, s26, v24, s27  # CHECK: [0x58,0xe9,0xad,0xc8]
shr_invmask v10, s26, v24, s27  # CHECK: [0x58,0xe9,0xad,0xcc]
shr v10, v24, v27  # CHECK: [0x58,0x81,0xad,0xd0]
shr_mask v10, s26, v24, v27  # CHECK: [0x58,0xe9,0xad,0xd4]
shr_invmask v10, s26, v24, v27  # CHECK: [0x58,0xe9,0xad,0xd8]
shr s10, s24, 75  # CHECK: [0x58,0x2d,0x01,0x05]
shr v10, v24, 75  # CHECK: [0x58,0x2d,0x01,0x15]
shr_mask v10, s26, v24, 75  # CHECK: [0x58,0xe9,0x25,0x25]
shr_invmask v10, s26, v24, 75  # CHECK: [0x58,0xe9,0x25,0x35]
shr v10, s24, 75  # CHECK: [0x58,0x2d,0x01,0x45]
shr_mask v10, s26, s24, 75  # CHECK: [0x58,0xe9,0x25,0x55]
shr_invmask v10, s26, s24, 75  # CHECK: [0x58,0xe9,0x25,0x65]
shl s19, s21, s11  # CHECK: [0x75,0x82,0xb5,0xc0]
shl v19, v21, s11  # CHECK: [0x75,0x82,0xb5,0xc4]
shl_mask v19, s0, v21, s11  # CHECK: [0x75,0x82,0xb5,0xc8]
shl_invmask v19, s0, v21, s11  # CHECK: [0x75,0x82,0xb5,0xcc]
shl v19, v21, v11  # CHECK: [0x75,0x82,0xb5,0xd0]
shl_mask v19, s0, v21, v11  # CHECK: [0x75,0x82,0xb5,0xd4]
shl_invmask v19, s0, v21, v11  # CHECK: [0x75,0x82,0xb5,0xd8]
shl s19, s21, 30  # CHECK: [0x75,0x7a,0x80,0x05]
shl v19, v21, 30  # CHECK: [0x75,0x7a,0x80,0x15]
shl_mask v19, s0, v21, 30  # CHECK: [0x75,0x02,0x8f,0x25]
shl_invmask v19, s0, v21, 30  # CHECK: [0x75,0x02,0x8f,0x35]
shl v19, s21, 30  # CHECK: [0x75,0x7a,0x80,0x45]
shl_mask v19, s0, s21, 30  # CHECK: [0x75,0x02,0x8f,0x55]
shl_invmask v19, s0, s21, 30  # CHECK: [0x75,0x02,0x8f,0x65]
add_f s4, s24, s24  # CHECK: [0x98,0x00,0x0c,0xc2]
add_f v4, v24, s24  # CHECK: [0x98,0x00,0x0c,0xc6]
add_f_mask v4, s10, v24, s24  # CHECK: [0x98,0x28,0x0c,0xca]
add_f_invmask v4, s10, v24, s24  # CHECK: [0x98,0x28,0x0c,0xce]
add_f v4, v24, v24  # CHECK: [0x98,0x00,0x0c,0xd2]
add_f_mask v4, s10, v24, v24  # CHECK: [0x98,0x28,0x0c,0xd6]
add_f_invmask v4, s10, v24, v24  # CHECK: [0x98,0x28,0x0c,0xda]
sub_f s0, s21, s2  # CHECK: [0x15,0x00,0x11,0xc2]
sub_f v0, v21, s2  # CHECK: [0x15,0x00,0x11,0xc6]
sub_f_mask v0, s4, v21, s2  # CHECK: [0x15,0x10,0x11,0xca]
sub_f_invmask v0, s4, v21, s2  # CHECK: [0x15,0x10,0x11,0xce]
sub_f v0, v21, v2  # CHECK: [0x15,0x00,0x11,0xd2]
sub_f_mask v0, s4, v21, v2  # CHECK: [0x15,0x10,0x11,0xd6]
sub_f_invmask v0, s4, v21, v2  # CHECK: [0x15,0x10,0x11,0xda]
mul_f s3, s11, s19  # CHECK: [0x6b,0x80,0x29,0xc2]
mul_f v3, v11, s19  # CHECK: [0x6b,0x80,0x29,0xc6]
mul_f_mask v3, s4, v11, s19  # CHECK: [0x6b,0x90,0x29,0xca]
mul_f_invmask v3, s4, v11, s19  # CHECK: [0x6b,0x90,0x29,0xce]
mul_f v3, v11, v19  # CHECK: [0x6b,0x80,0x29,0xd2]
mul_f_mask v3, s4, v11, v19  # CHECK: [0x6b,0x90,0x29,0xd6]
mul_f_invmask v3, s4, v11, v19  # CHECK: [0x6b,0x90,0x29,0xda]
clz s0, s9  # CHECK: [0x00,0x80,0xc4,0xc0]
clz v0, s9  # CHECK: [0x00,0x80,0xc4,0xc4]
clz_mask v0, s2, s9  # CHECK: [0x00,0x88,0xc4,0xc8]
clz_invmask v0, s2, s9  # CHECK: [0x00,0x88,0xc4,0xcc]
clz v0, v9  # CHECK: [0x00,0x80,0xc4,0xd0]
clz_mask v0, s2, v9  # CHECK: [0x00,0x88,0xc4,0xd4]
clz_invmask v0, s2, v9  # CHECK: [0x00,0x88,0xc4,0xd8]
ctz s0, s11  # CHECK: [0x00,0x80,0xe5,0xc0]
ctz v0, s11  # CHECK: [0x00,0x80,0xe5,0xc4]
ctz_mask v0, s20, s11  # CHECK: [0x00,0xd0,0xe5,0xc8]
ctz_invmask v0, s20, s11  # CHECK: [0x00,0xd0,0xe5,0xcc]
ctz v0, v11  # CHECK: [0x00,0x80,0xe5,0xd0]
ctz_mask v0, s20, v11  # CHECK: [0x00,0xd0,0xe5,0xd4]
ctz_invmask v0, s20, v11  # CHECK: [0x00,0xd0,0xe5,0xd8]
move s21, s17  # CHECK: [0xa0,0x82,0xf8,0xc0]
move v21, s17  # CHECK: [0xa0,0x82,0xf8,0xc4]
move_mask v21, s0, s17  # CHECK: [0xa0,0x82,0xf8,0xc8]
move_invmask v21, s0, s17  # CHECK: [0xa0,0x82,0xf8,0xcc]
move v21, v17  # CHECK: [0xa0,0x82,0xf8,0xd0]
move_mask v21, s0, v17  # CHECK: [0xa0,0x82,0xf8,0xd4]
move_invmask v21, s0, v17  # CHECK: [0xa0,0x82,0xf8,0xd8]
reciprocal s7, s9  # CHECK: [0xe0,0x80,0xc4,0xc1]
shuffle v1, v2, v3  # CHECK: [0x22,0x80,0xd1,0xd0]
shuffle_mask v1, s4, v2, v3  # CHECK: [0x22,0x90,0xd1,0xd4]
shuffle_invmask v1, s4, v2, v3  # CHECK: [0x22,0x90,0xd1,0xd8]
getfield s4, v5, s6  # CHECK: [0x85,0x00,0xa3,0xc5]
setgt_i s21, s17, s19  # CHECK: [0xb1,0x82,0x29,0xc1]
setgt_i s21, v17, s19  # CHECK: [0xb1,0x82,0x29,0xc5]
setgt_i s21, v17, v19  # CHECK: [0xb1,0x82,0x29,0xd1]
setgt_i s21, s17, 222  # CHECK: [0xb1,0x7a,0x03,0x09]
setgt_i s21, v17, 222  # CHECK: [0xb1,0x7a,0x03,0x19]
setge_i s21, s17, s19  # CHECK: [0xb1,0x82,0x39,0xc1]
setge_i s21, v17, s19  # CHECK: [0xb1,0x82,0x39,0xc5]
setge_i s21, v17, v19  # CHECK: [0xb1,0x82,0x39,0xd1]
setge_i s21, s17, 18  # CHECK: [0xb1,0x4a,0x80,0x09]
setge_i s21, v17, 18  # CHECK: [0xb1,0x4a,0x80,0x19]
setlt_i s21, s17, s19  # CHECK: [0xb1,0x82,0x49,0xc1]
setlt_i s21, v17, s19  # CHECK: [0xb1,0x82,0x49,0xc5]
setlt_i s21, v17, v19  # CHECK: [0xb1,0x82,0x49,0xd1]
setlt_i s21, s17, 72  # CHECK: [0xb1,0x22,0x01,0x0a]
setlt_i s21, v17, 72  # CHECK: [0xb1,0x22,0x01,0x1a]
setle_i s21, s17, s19  # CHECK: [0xb1,0x82,0x59,0xc1]
setle_i s21, v17, s19  # CHECK: [0xb1,0x82,0x59,0xc5]
setle_i s21, v17, v19  # CHECK: [0xb1,0x82,0x59,0xd1]
setle_i s21, s17, 78  # CHECK: [0xb1,0x3a,0x81,0x0a]
setle_i s21, v17, 78  # CHECK: [0xb1,0x3a,0x81,0x1a]
setgt_u s21, s17, s19  # CHECK: [0xb1,0x82,0x69,0xc1]
setgt_u s21, v17, s19  # CHECK: [0xb1,0x82,0x69,0xc5]
setgt_u s21, v17, v19  # CHECK: [0xb1,0x82,0x69,0xd1]
setgt_u s21, s17, 56  # CHECK: [0xb1,0xe2,0x00,0x0b]
setgt_u s21, v17, 56  # CHECK: [0xb1,0xe2,0x00,0x1b]
setge_u s21, s17, s19  # CHECK: [0xb1,0x82,0x79,0xc1]
setge_u s21, v17, s19  # CHECK: [0xb1,0x82,0x79,0xc5]
setge_u s21, v17, v19  # CHECK: [0xb1,0x82,0x79,0xd1]
setge_u s21, s17, 163  # CHECK: [0xb1,0x8e,0x82,0x0b]
setge_u s21, v17, 163  # CHECK: [0xb1,0x8e,0x82,0x1b]
setlt_u s21, s17, s19  # CHECK: [0xb1,0x82,0x89,0xc1]
setlt_u s21, v17, s19  # CHECK: [0xb1,0x82,0x89,0xc5]
setlt_u s21, v17, v19  # CHECK: [0xb1,0x82,0x89,0xd1]
setlt_u s21, s17, 223  # CHECK: [0xb1,0x7e,0x03,0x0c]
setlt_u s21, v17, 223  # CHECK: [0xb1,0x7e,0x03,0x1c]
setle_u s21, s17, s19  # CHECK: [0xb1,0x82,0x99,0xc1]
setle_u s21, v17, s19  # CHECK: [0xb1,0x82,0x99,0xc5]
setle_u s21, v17, v19  # CHECK: [0xb1,0x82,0x99,0xd1]
setle_u s21, s17, 153  # CHECK: [0xb1,0x66,0x82,0x0c]
setle_u s21, v17, 153  # CHECK: [0xb1,0x66,0x82,0x1c]
setgt_f s21, s17, s19  # CHECK: [0xb1,0x82,0xc9,0xc2]
setgt_f s21, v17, s19  # CHECK: [0xb1,0x82,0xc9,0xc6]
setgt_f s21, v17, v19  # CHECK: [0xb1,0x82,0xc9,0xd2]
setge_f s21, s17, s19  # CHECK: [0xb1,0x82,0xd9,0xc2]
setge_f s21, v17, s19  # CHECK: [0xb1,0x82,0xd9,0xc6]
setge_f s21, v17, v19  # CHECK: [0xb1,0x82,0xd9,0xd2]
setlt_f s21, s17, s19  # CHECK: [0xb1,0x82,0xe9,0xc2]
setlt_f s21, v17, s19  # CHECK: [0xb1,0x82,0xe9,0xc6]
setlt_f s21, v17, v19  # CHECK: [0xb1,0x82,0xe9,0xd2]
setle_f s21, s17, s19  # CHECK: [0xb1,0x82,0xf9,0xc2]
setle_f s21, v17, s19  # CHECK: [0xb1,0x82,0xf9,0xc6]
setle_f s21, v17, v19  # CHECK: [0xb1,0x82,0xf9,0xd2]
getfield s1, v2, s3   # CHECK: [0x22,0x80,0xa1,0xc5]
load_u8 s10, 20(s5)  # CHECK: [0x45,0x51,0x00,0xa0]
load_u8 s11, (s6)  # CHECK: [0x66,0x01,0x00,0xa0]
load_s8 s10, 20(s5)  # CHECK: [0x45,0x51,0x00,0xa2]
load_s8 s11, (s6)  # CHECK: [0x66,0x01,0x00,0xa2]
load_u16 s12, 30(s7)  # CHECK: [0x87,0x79,0x00,0xa4]
load_u16 s13, (s8)  # CHECK: [0xa8,0x01,0x00,0xa4]
load_s16 s12, 30(s7)  # CHECK: [0x87,0x79,0x00,0xa6]
load_s16 s13, (s8)  # CHECK: [0xa8,0x01,0x00,0xa6]
load_32 s14, 40(s9)  # CHECK: [0xc9,0xa1,0x00,0xa8]
load_32 s15, (s10)  # CHECK: [0xea,0x01,0x00,0xa8]
store_8 s1, 50(s2)  # CHECK: [0x22,0xc8,0x00,0x82]
store_16 s3, 60(s4)  # CHECK: [0x64,0xf0,0x00,0x86]
store_32 s5, 70(s6)  # CHECK: [0xa6,0x18,0x01,0x88]
load_v v2, 20(s5)  # CHECK: [0x45,0x50,0x00,0xae]
load_v v3, (s6)  # CHECK: [0x66,0x00,0x00,0xae]
store_v v2, 20(s5)  # CHECK: [0x45,0x50,0x00,0x8e]
store_v v3, (s6)  # CHECK: [0x66,0x00,0x00,0x8e]
load_v_mask v2, s7, 20(s5)  # CHECK: [0x45,0x1c,0x0a,0xb0]
load_v_mask v3, s7, (s6)  # CHECK: [0x66,0x1c,0x00,0xb0]
load_v_invmask v2, s7, 20(s5)  # CHECK: [0x45,0x1c,0x0a,0xb2]
load_v_invmask v3, s7, (s6)  # CHECK: [0x66,0x1c,0x00,0xb2]
store_v_mask v2, s7, 20(s5)  # CHECK: [0x45,0x1c,0x0a,0x90]
store_v_mask v3, s7, (s6)  # CHECK: [0x66,0x1c,0x00,0x90]
store_v_invmask v2, s7, 20(s5)  # CHECK: [0x45,0x1c,0x0a,0x92]
store_v_invmask v3, s7, (s6)  # CHECK: [0x66,0x1c,0x00,0x92]
store_scat v2, (v5)  # CHECK: [0x45,0x00,0x00,0x9a]
store_scat_mask v3, s7, (v6)  # CHECK: [0x66,0x1c,0x00,0x9c]
load_sync s2, 20(s5)  # CHECK: [0x45,0x50,0x00,0xaa]
load_sync s3, (s6)  # CHECK: [0x66,0x00,0x00,0xaa]
store_sync s2, 20(s5)  # CHECK: [0x45,0x50,0x00,0x8a]
store_sync s3, (s6)  # CHECK: [0x66,0x00,0x00,0x8a]
getcr s7, 9  # CHECK: [0xe9,0x00,0x00,0xac]
setcr s11, 13  # CHECK: [0x6d,0x01,0x00,0x8c]
