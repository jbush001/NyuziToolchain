// RUN: spmd-compile %s -S -o - | FileCheck %s

float ifstmt(float a, float b)
{
    // CHECK: load_32 s1, .LCPI0_0

    float retval = 0;
    // CHECK: move v2, s1

	if (a > 0) {
        // CHECK: cmpgt_f s0, v0, s1
        // CHECK: bfalse s0, .LBB0_2
        retval = a - b;
        // CHECK: sub_f_mask v2, s0, v0, v1
	} else {
        // CHECK: .LBB0_2:
        // CHECK: load_32 s1, .LCPI0_1
        // CHECK: and s0, s0, s1
        // CHECK: cmpeq_i s2, s0, s1
        // CHECK: btrue s2, .LBB0_4
        // CHECK: xor s0, s0, s1
        retval = b;
        // CHECK: 	move_mask v2, s0, v1
    }

    // CHECK: .LBB0_4:
    return retval;
    // CHECK: move_mask v0, s1, v2
    // CHECK: 	ret
}

