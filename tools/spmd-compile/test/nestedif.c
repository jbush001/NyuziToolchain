// RUN: spmd-compile %s -S -o - | FileCheck %s

float nestedif(float a, float b)
{
    float retval = 0;

	if (a > b) {
        // CHECK: cmpgt_f s1, v0, v1
        // CHECK: load_32 s0, .LCPI0_1
        // CHECK: bfalse s1, .LBB0_1
		if (a > 0) {
            // CHECK: cmpgt_f s2, v0, s0
            // CHECK: move v2, s0
            // CHECK: and s3, s2, s1
            // CHECK: bfalse s3, .LBB0_4
            retval = a - b;
            // CHECK: sub_f_mask v2, s3, v0, v1
		} else {
            // CHECK: .LBB0_4:
            // CHECK: xor s2, s2, s3
            // CHECK: and s1, s1, s3
            // CHECK: and s2, s1, s2
            // CHECK: bfalse s2, .LBB0_5
            retval = b;
            // CHECK: move_mask v2, s2, v1
            // CHECK: goto .LBB0_6
        }
	} else {
        // CHECK: .LBB0_1:
        // CHECK: move v2, s0
		if (b > 0) {
            // CHECK: .LBB0_6:
            // CHECK: cmpgt_f s0, v1, s0
            // CHECK: and s2, s0, s1
            // CHECK: bfalse s2, .LBB0_8
            retval = b - a;
            // CHECK: sub_f_mask v2, s2, v1, v0
		} else {
            // CHECK: .LBB0_8:
            // CHECK: xor s0, s0, -1
            // CHECK: and s0, s1, s0
            // CHECK: bfalse s0, .LBB0_10
            retval = a;
            // CHECK: move_mask v2, s0, v0
        }
    }

    // CHECK: .LBB0_10:
    return retval;
    // CHECK: move_mask v0, s0, v2
    // CHECK: ret
}


