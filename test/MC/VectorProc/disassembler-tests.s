# This file auto-generated by make_tests.py. Do not edit.
# RUN: llvm-mc -arch=vectorproc -disassemble %s | FileCheck %s
0x4d 0x80 0x01 0xc0  # CHECK: or s2, s13, s3
0x4d 0x80 0x01 0xc4  # CHECK: or v2, v13, s3
0x4d 0xa8 0x01 0xc8  # CHECK: or_mask v2, s10, v13, s3
0x4d 0xa8 0x01 0xcc  # CHECK: or_invmask v2, s10, v13, s3
0x4d 0x80 0x01 0xd0  # CHECK: or v2, v13, v3
0x4d 0xa8 0x01 0xd4  # CHECK: or_mask v2, s10, v13, v3
0x4d 0xa8 0x01 0xd8  # CHECK: or_invmask v2, s10, v13, v3
0x4d 0xdc 0x00 0x00  # CHECK: or s2, s13, 55
0x4d 0xdc 0x00 0x10  # CHECK: or v2, v13, 55
0x4d 0xa8 0x1b 0x20  # CHECK: or_mask v2, s10, v13, 55
0x4d 0xa8 0x1b 0x30  # CHECK: or_invmask v2, s10, v13, 55
0x4d 0xdc 0x00 0x40  # CHECK: or v2, s13, 55
0x4d 0xa8 0x1b 0x50  # CHECK: or_mask v2, s10, s13, 55
0x4d 0xa8 0x1b 0x60  # CHECK: or_invmask v2, s10, s13, 55
0xf5 0x01 0x15 0xc0  # CHECK: and s15, s21, s10
0xf5 0x01 0x15 0xc4  # CHECK: and v15, v21, s10
0xf5 0x11 0x15 0xc8  # CHECK: and_mask v15, s4, v21, s10
0xf5 0x11 0x15 0xcc  # CHECK: and_invmask v15, s4, v21, s10
0xf5 0x01 0x15 0xd0  # CHECK: and v15, v21, v10
0xf5 0x11 0x15 0xd4  # CHECK: and_mask v15, s4, v21, v10
0xf5 0x11 0x15 0xd8  # CHECK: and_invmask v15, s4, v21, v10
0xf5 0xe5 0x83 0x00  # CHECK: and s15, s21, 249
0xf5 0xe5 0x83 0x10  # CHECK: and v15, v21, 249
0xf5 0x91 0xfc 0x20  # CHECK: and_mask v15, s4, v21, 249
0xf5 0x91 0xfc 0x30  # CHECK: and_invmask v15, s4, v21, 249
0xf5 0xe5 0x83 0x40  # CHECK: and v15, s21, 249
0xf5 0x91 0xfc 0x50  # CHECK: and_mask v15, s4, s21, 249
0xf5 0x91 0xfc 0x60  # CHECK: and_invmask v15, s4, s21, 249
0x6c 0x00 0x35 0xc0  # CHECK: xor s3, s12, s10
0x6c 0x00 0x35 0xc4  # CHECK: xor v3, v12, s10
0x6c 0x48 0x35 0xc8  # CHECK: xor_mask v3, s18, v12, s10
0x6c 0x48 0x35 0xcc  # CHECK: xor_invmask v3, s18, v12, s10
0x6c 0x00 0x35 0xd0  # CHECK: xor v3, v12, v10
0x6c 0x48 0x35 0xd4  # CHECK: xor_mask v3, s18, v12, v10
0x6c 0x48 0x35 0xd8  # CHECK: xor_invmask v3, s18, v12, v10
0x6c 0x74 0x82 0x01  # CHECK: xor s3, s12, 157
0x6c 0x74 0x82 0x11  # CHECK: xor v3, v12, 157
0x6c 0xc8 0xce 0x21  # CHECK: xor_mask v3, s18, v12, 157
0x6c 0xc8 0xce 0x31  # CHECK: xor_invmask v3, s18, v12, 157
0x6c 0x74 0x82 0x41  # CHECK: xor v3, s12, 157
0x6c 0xc8 0xce 0x51  # CHECK: xor_mask v3, s18, s12, 157
0x6c 0xc8 0xce 0x61  # CHECK: xor_invmask v3, s18, s12, 157
0x31 0x02 0x51 0xc0  # CHECK: add_i s17, s17, s2
0x31 0x02 0x51 0xc4  # CHECK: add_i v17, v17, s2
0x31 0x3e 0x51 0xc8  # CHECK: add_i_mask v17, s15, v17, s2
0x31 0x3e 0x51 0xcc  # CHECK: add_i_invmask v17, s15, v17, s2
0x31 0x02 0x51 0xd0  # CHECK: add_i v17, v17, v2
0x31 0x3e 0x51 0xd4  # CHECK: add_i_mask v17, s15, v17, v2
0x31 0x3e 0x51 0xd8  # CHECK: add_i_invmask v17, s15, v17, v2
0x31 0xa6 0x80 0x02  # CHECK: add_i s17, s17, 41
0x31 0xa6 0x80 0x12  # CHECK: add_i v17, v17, 41
0x31 0xbe 0x94 0x22  # CHECK: add_i_mask v17, s15, v17, 41
0x31 0xbe 0x94 0x32  # CHECK: add_i_invmask v17, s15, v17, 41
0x31 0xa6 0x80 0x42  # CHECK: add_i v17, s17, 41
0x31 0xbe 0x94 0x52  # CHECK: add_i_mask v17, s15, s17, 41
0x31 0xbe 0x94 0x62  # CHECK: add_i_invmask v17, s15, s17, 41
0x63 0x01 0x61 0xc0  # CHECK: sub_i s11, s3, s2
0x63 0x01 0x61 0xc4  # CHECK: sub_i v11, v3, s2
0x63 0x11 0x61 0xc8  # CHECK: sub_i_mask v11, s4, v3, s2
0x63 0x11 0x61 0xcc  # CHECK: sub_i_invmask v11, s4, v3, s2
0x63 0x01 0x61 0xd0  # CHECK: sub_i v11, v3, v2
0x63 0x11 0x61 0xd4  # CHECK: sub_i_mask v11, s4, v3, v2
0x63 0x11 0x61 0xd8  # CHECK: sub_i_invmask v11, s4, v3, v2
0x63 0xf5 0x01 0x03  # CHECK: sub_i s11, s3, 125
0x63 0xf5 0x01 0x13  # CHECK: sub_i v11, v3, 125
0x63 0x91 0x3e 0x23  # CHECK: sub_i_mask v11, s4, v3, 125
0x63 0x91 0x3e 0x33  # CHECK: sub_i_invmask v11, s4, v3, 125
0x63 0xf5 0x01 0x43  # CHECK: sub_i v11, s3, 125
0x63 0x91 0x3e 0x53  # CHECK: sub_i_mask v11, s4, s3, 125
0x63 0x91 0x3e 0x63  # CHECK: sub_i_invmask v11, s4, s3, 125
0x99 0x81 0x7a 0xc0  # CHECK: mul_i s12, s25, s21
0x99 0x81 0x7a 0xc4  # CHECK: mul_i v12, v25, s21
0x99 0x99 0x7a 0xc8  # CHECK: mul_i_mask v12, s6, v25, s21
0x99 0x99 0x7a 0xcc  # CHECK: mul_i_invmask v12, s6, v25, s21
0x99 0x81 0x7a 0xd0  # CHECK: mul_i v12, v25, v21
0x99 0x99 0x7a 0xd4  # CHECK: mul_i_mask v12, s6, v25, v21
0x99 0x99 0x7a 0xd8  # CHECK: mul_i_invmask v12, s6, v25, v21
0x99 0x39 0x82 0x03  # CHECK: mul_i s12, s25, 142
0x99 0x39 0x82 0x13  # CHECK: mul_i v12, v25, 142
0x99 0x19 0xc7 0x23  # CHECK: mul_i_mask v12, s6, v25, 142
0x99 0x19 0xc7 0x33  # CHECK: mul_i_invmask v12, s6, v25, 142
0x99 0x39 0x82 0x43  # CHECK: mul_i v12, s25, 142
0x99 0x19 0xc7 0x53  # CHECK: mul_i_mask v12, s6, s25, 142
0x99 0x19 0xc7 0x63  # CHECK: mul_i_invmask v12, s6, s25, 142
0x77 0x02 0x97 0xc0  # CHECK: ashr s19, s23, s14
0x77 0x02 0x97 0xc4  # CHECK: ashr v19, v23, s14
0x77 0x52 0x97 0xc8  # CHECK: ashr_mask v19, s20, v23, s14
0x77 0x52 0x97 0xcc  # CHECK: ashr_invmask v19, s20, v23, s14
0x77 0x02 0x97 0xd0  # CHECK: ashr v19, v23, v14
0x77 0x52 0x97 0xd4  # CHECK: ashr_mask v19, s20, v23, v14
0x77 0x52 0x97 0xd8  # CHECK: ashr_invmask v19, s20, v23, v14
0x77 0xe6 0x80 0x04  # CHECK: ashr s19, s23, 57
0x77 0xe6 0x80 0x14  # CHECK: ashr v19, v23, 57
0x77 0xd2 0x9c 0x24  # CHECK: ashr_mask v19, s20, v23, 57
0x77 0xd2 0x9c 0x34  # CHECK: ashr_invmask v19, s20, v23, 57
0x77 0xe6 0x80 0x44  # CHECK: ashr v19, s23, 57
0x77 0xd2 0x9c 0x54  # CHECK: ashr_mask v19, s20, s23, 57
0x77 0xd2 0x9c 0x64  # CHECK: ashr_invmask v19, s20, s23, 57
0x58 0x81 0xad 0xc0  # CHECK: shr s10, s24, s27
0x58 0x81 0xad 0xc4  # CHECK: shr v10, v24, s27
0x58 0xe9 0xad 0xc8  # CHECK: shr_mask v10, s26, v24, s27
0x58 0xe9 0xad 0xcc  # CHECK: shr_invmask v10, s26, v24, s27
0x58 0x81 0xad 0xd0  # CHECK: shr v10, v24, v27
0x58 0xe9 0xad 0xd4  # CHECK: shr_mask v10, s26, v24, v27
0x58 0xe9 0xad 0xd8  # CHECK: shr_invmask v10, s26, v24, v27
0x58 0x2d 0x01 0x05  # CHECK: shr s10, s24, 75
0x58 0x2d 0x01 0x15  # CHECK: shr v10, v24, 75
0x58 0xe9 0x25 0x25  # CHECK: shr_mask v10, s26, v24, 75
0x58 0xe9 0x25 0x35  # CHECK: shr_invmask v10, s26, v24, 75
0x58 0x2d 0x01 0x45  # CHECK: shr v10, s24, 75
0x58 0xe9 0x25 0x55  # CHECK: shr_mask v10, s26, s24, 75
0x58 0xe9 0x25 0x65  # CHECK: shr_invmask v10, s26, s24, 75
0x75 0x82 0xb5 0xc0  # CHECK: shl s19, s21, s11
0x75 0x82 0xb5 0xc4  # CHECK: shl v19, v21, s11
0x75 0x82 0xb5 0xc8  # CHECK: shl_mask v19, s0, v21, s11
0x75 0x82 0xb5 0xcc  # CHECK: shl_invmask v19, s0, v21, s11
0x75 0x82 0xb5 0xd0  # CHECK: shl v19, v21, v11
0x75 0x82 0xb5 0xd4  # CHECK: shl_mask v19, s0, v21, v11
0x75 0x82 0xb5 0xd8  # CHECK: shl_invmask v19, s0, v21, v11
0x75 0x7a 0x80 0x05  # CHECK: shl s19, s21, 30
0x75 0x7a 0x80 0x15  # CHECK: shl v19, v21, 30
0x75 0x02 0x8f 0x25  # CHECK: shl_mask v19, s0, v21, 30
0x75 0x02 0x8f 0x35  # CHECK: shl_invmask v19, s0, v21, 30
0x75 0x7a 0x80 0x45  # CHECK: shl v19, s21, 30
0x75 0x02 0x8f 0x55  # CHECK: shl_mask v19, s0, s21, 30
0x75 0x02 0x8f 0x65  # CHECK: shl_invmask v19, s0, s21, 30
0x98 0x00 0x0c 0xc2  # CHECK: add_f s4, s24, s24
0x98 0x00 0x0c 0xc6  # CHECK: add_f v4, v24, s24
0x98 0x28 0x0c 0xca  # CHECK: add_f_mask v4, s10, v24, s24
0x98 0x28 0x0c 0xce  # CHECK: add_f_invmask v4, s10, v24, s24
0x98 0x00 0x0c 0xd2  # CHECK: add_f v4, v24, v24
0x98 0x28 0x0c 0xd6  # CHECK: add_f_mask v4, s10, v24, v24
0x98 0x28 0x0c 0xda  # CHECK: add_f_invmask v4, s10, v24, v24
0x15 0x00 0x11 0xc2  # CHECK: sub_f s0, s21, s2
0x15 0x00 0x11 0xc6  # CHECK: sub_f v0, v21, s2
0x15 0x10 0x11 0xca  # CHECK: sub_f_mask v0, s4, v21, s2
0x15 0x10 0x11 0xce  # CHECK: sub_f_invmask v0, s4, v21, s2
0x15 0x00 0x11 0xd2  # CHECK: sub_f v0, v21, v2
0x15 0x10 0x11 0xd6  # CHECK: sub_f_mask v0, s4, v21, v2
0x15 0x10 0x11 0xda  # CHECK: sub_f_invmask v0, s4, v21, v2
0x6b 0x80 0x29 0xc2  # CHECK: mul_f s3, s11, s19
0x6b 0x80 0x29 0xc6  # CHECK: mul_f v3, v11, s19
0x6b 0x90 0x29 0xca  # CHECK: mul_f_mask v3, s4, v11, s19
0x6b 0x90 0x29 0xce  # CHECK: mul_f_invmask v3, s4, v11, s19
0x6b 0x80 0x29 0xd2  # CHECK: mul_f v3, v11, v19
0x6b 0x90 0x29 0xd6  # CHECK: mul_f_mask v3, s4, v11, v19
0x6b 0x90 0x29 0xda  # CHECK: mul_f_invmask v3, s4, v11, v19
0x00 0x80 0xc4 0xc0  # CHECK: clz s0, s9
0x00 0x80 0xc4 0xc4  # CHECK: clz v0, s9
0x00 0x88 0xc4 0xc8  # CHECK: clz_mask v0, s2, s9
0x00 0x88 0xc4 0xcc  # CHECK: clz_invmask v0, s2, s9
0x00 0x80 0xc4 0xd0  # CHECK: clz v0, v9
0x00 0x88 0xc4 0xd4  # CHECK: clz_mask v0, s2, v9
0x00 0x88 0xc4 0xd8  # CHECK: clz_invmask v0, s2, v9
0x00 0x80 0xe5 0xc0  # CHECK: ctz s0, s11
0x00 0x80 0xe5 0xc4  # CHECK: ctz v0, s11
0x00 0xd0 0xe5 0xc8  # CHECK: ctz_mask v0, s20, s11
0x00 0xd0 0xe5 0xcc  # CHECK: ctz_invmask v0, s20, s11
0x00 0x80 0xe5 0xd0  # CHECK: ctz v0, v11
0x00 0xd0 0xe5 0xd4  # CHECK: ctz_mask v0, s20, v11
0x00 0xd0 0xe5 0xd8  # CHECK: ctz_invmask v0, s20, v11
0xa0 0x82 0xf8 0xc0  # CHECK: move s21, s17
0xa0 0x82 0xf8 0xc4  # CHECK: move v21, s17
0xa0 0x82 0xf8 0xc8  # CHECK: move_mask v21, s0, s17
0xa0 0x82 0xf8 0xcc  # CHECK: move_invmask v21, s0, s17
0xa0 0x82 0xf8 0xd0  # CHECK: move v21, v17
0xa0 0x82 0xf8 0xd4  # CHECK: move_mask v21, s0, v17
0xa0 0x82 0xf8 0xd8  # CHECK: move_invmask v21, s0, v17
0xe0 0x80 0xc4 0xc1  # CHECK: reciprocal s7, s9
0x22 0x80 0xd1 0xd0  # CHECK: shuffle v1, v2, v3
0x22 0x90 0xd1 0xd4  # CHECK: shuffle_mask v1, s4, v2, v3
0x22 0x90 0xd1 0xd8  # CHECK: shuffle_invmask v1, s4, v2, v3
0x85 0x00 0xa3 0xc5  # CHECK: getfield s4, v5, s6
0xb1 0x82 0x29 0xc1  # CHECK: setgt_i s21, s17, s19
0xb1 0x82 0x29 0xc5  # CHECK: setgt_i s21, v17, s19
0xb1 0x82 0x29 0xd1  # CHECK: setgt_i s21, v17, v19
0xb1 0x7a 0x03 0x09  # CHECK: setgt_i s21, s17, 222
0xb1 0x7a 0x03 0x19  # CHECK: setgt_i s21, v17, 222
0xb1 0x82 0x39 0xc1  # CHECK: setge_i s21, s17, s19
0xb1 0x82 0x39 0xc5  # CHECK: setge_i s21, v17, s19
0xb1 0x82 0x39 0xd1  # CHECK: setge_i s21, v17, v19
0xb1 0x4a 0x80 0x09  # CHECK: setge_i s21, s17, 18
0xb1 0x4a 0x80 0x19  # CHECK: setge_i s21, v17, 18
0xb1 0x82 0x49 0xc1  # CHECK: setlt_i s21, s17, s19
0xb1 0x82 0x49 0xc5  # CHECK: setlt_i s21, v17, s19
0xb1 0x82 0x49 0xd1  # CHECK: setlt_i s21, v17, v19
0xb1 0x22 0x01 0x0a  # CHECK: setlt_i s21, s17, 72
0xb1 0x22 0x01 0x1a  # CHECK: setlt_i s21, v17, 72
0xb1 0x82 0x59 0xc1  # CHECK: setle_i s21, s17, s19
0xb1 0x82 0x59 0xc5  # CHECK: setle_i s21, v17, s19
0xb1 0x82 0x59 0xd1  # CHECK: setle_i s21, v17, v19
0xb1 0x3a 0x81 0x0a  # CHECK: setle_i s21, s17, 78
0xb1 0x3a 0x81 0x1a  # CHECK: setle_i s21, v17, 78
0xb1 0x82 0x69 0xc1  # CHECK: setgt_u s21, s17, s19
0xb1 0x82 0x69 0xc5  # CHECK: setgt_u s21, v17, s19
0xb1 0x82 0x69 0xd1  # CHECK: setgt_u s21, v17, v19
0xb1 0xe2 0x00 0x0b  # CHECK: setgt_u s21, s17, 56
0xb1 0xe2 0x00 0x1b  # CHECK: setgt_u s21, v17, 56
0xb1 0x82 0x79 0xc1  # CHECK: setge_u s21, s17, s19
0xb1 0x82 0x79 0xc5  # CHECK: setge_u s21, v17, s19
0xb1 0x82 0x79 0xd1  # CHECK: setge_u s21, v17, v19
0xb1 0x8e 0x82 0x0b  # CHECK: setge_u s21, s17, 163
0xb1 0x8e 0x82 0x1b  # CHECK: setge_u s21, v17, 163
0xb1 0x82 0x89 0xc1  # CHECK: setlt_u s21, s17, s19
0xb1 0x82 0x89 0xc5  # CHECK: setlt_u s21, v17, s19
0xb1 0x82 0x89 0xd1  # CHECK: setlt_u s21, v17, v19
0xb1 0x7e 0x03 0x0c  # CHECK: setlt_u s21, s17, 223
0xb1 0x7e 0x03 0x1c  # CHECK: setlt_u s21, v17, 223
0xb1 0x82 0x99 0xc1  # CHECK: setle_u s21, s17, s19
0xb1 0x82 0x99 0xc5  # CHECK: setle_u s21, v17, s19
0xb1 0x82 0x99 0xd1  # CHECK: setle_u s21, v17, v19
0xb1 0x66 0x82 0x0c  # CHECK: setle_u s21, s17, 153
0xb1 0x66 0x82 0x1c  # CHECK: setle_u s21, v17, 153
0xb1 0x82 0xc9 0xc2  # CHECK: setgt_f s21, s17, s19
0xb1 0x82 0xc9 0xc6  # CHECK: setgt_f s21, v17, s19
0xb1 0x82 0xc9 0xd2  # CHECK: setgt_f s21, v17, v19
0xb1 0x82 0xd9 0xc2  # CHECK: setge_f s21, s17, s19
0xb1 0x82 0xd9 0xc6  # CHECK: setge_f s21, v17, s19
0xb1 0x82 0xd9 0xd2  # CHECK: setge_f s21, v17, v19
0xb1 0x82 0xe9 0xc2  # CHECK: setlt_f s21, s17, s19
0xb1 0x82 0xe9 0xc6  # CHECK: setlt_f s21, v17, s19
0xb1 0x82 0xe9 0xd2  # CHECK: setlt_f s21, v17, v19
0xb1 0x82 0xf9 0xc2  # CHECK: setle_f s21, s17, s19
0xb1 0x82 0xf9 0xc6  # CHECK: setle_f s21, v17, s19
0xb1 0x82 0xf9 0xd2  # CHECK: setle_f s21, v17, v19
0x22 0x80 0xa1 0xc5  # CHECK: getfield s1, v2, s3 
0x45 0x51 0x00 0xa0  # CHECK: load_u8 s10, 20(s5)
0x66 0x01 0x00 0xa0  # CHECK: load_u8 s11, (s6)
0x45 0x51 0x00 0xa2  # CHECK: load_s8 s10, 20(s5)
0x66 0x01 0x00 0xa2  # CHECK: load_s8 s11, (s6)
0x87 0x79 0x00 0xa4  # CHECK: load_u16 s12, 30(s7)
0xa8 0x01 0x00 0xa4  # CHECK: load_u16 s13, (s8)
0x87 0x79 0x00 0xa6  # CHECK: load_s16 s12, 30(s7)
0xa8 0x01 0x00 0xa6  # CHECK: load_s16 s13, (s8)
0xc9 0xa1 0x00 0xa8  # CHECK: load_32 s14, 40(s9)
0xea 0x01 0x00 0xa8  # CHECK: load_32 s15, (s10)
0x22 0xc8 0x00 0x82  # CHECK: store_8 s1, 50(s2)
0x64 0xf0 0x00 0x86  # CHECK: store_16 s3, 60(s4)
0xa6 0x18 0x01 0x88  # CHECK: store_32 s5, 70(s6)
0x45 0x50 0x00 0xae  # CHECK: load_v v2, 20(s5)
0x66 0x00 0x00 0xae  # CHECK: load_v v3, (s6)
0x45 0x50 0x00 0x8e  # CHECK: store_v v2, 20(s5)
0x66 0x00 0x00 0x8e  # CHECK: store_v v3, (s6)
0x45 0x1c 0x0a 0xb0  # CHECK: load_v_mask v2, s7, 20(s5)
0x66 0x1c 0x00 0xb0  # CHECK: load_v_mask v3, s7, (s6)
0x45 0x1c 0x0a 0xb2  # CHECK: load_v_invmask v2, s7, 20(s5)
0x66 0x1c 0x00 0xb2  # CHECK: load_v_invmask v3, s7, (s6)
0x45 0x1c 0x0a 0x90  # CHECK: store_v_mask v2, s7, 20(s5)
0x66 0x1c 0x00 0x90  # CHECK: store_v_mask v3, s7, (s6)
0x45 0x1c 0x0a 0x92  # CHECK: store_v_invmask v2, s7, 20(s5)
0x66 0x1c 0x00 0x92  # CHECK: store_v_invmask v3, s7, (s6)
0x45 0x00 0x00 0x9a  # CHECK: store_scat v2, (v5)
0x66 0x1c 0x00 0x9c  # CHECK: store_scat_mask v3, s7, (v6)
0x45 0x50 0x00 0xaa  # CHECK: load_sync s2, 20(s5)
0x66 0x00 0x00 0xaa  # CHECK: load_sync s3, (s6)
0x45 0x50 0x00 0x8a  # CHECK: store_sync s2, 20(s5)
0x66 0x00 0x00 0x8a  # CHECK: store_sync s3, (s6)
0xe9 0x00 0x00 0xac  # CHECK: getcr s7, 9
0x6d 0x01 0x00 0x8c  # CHECK: setcr s11, 13
