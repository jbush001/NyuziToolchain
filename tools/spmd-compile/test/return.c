// RUN: spmd-compile %s -S -o - | FileCheck %s

float returnstmt(float a, float count)
{
    if (a > count) {
    	// CHECK: cmpgt_f s0, v0, v1

        // Early out if no lanes match
    	// CHECK: bfalse s0, .LBB0_1
        return a;

        // CHECK: move_mask v0, s0, v0
    	// CHECK: load_32 s1, .LCPI0_0
    	// CHECK: and s0, s0, s1
    	// CHECK: cmpeq_i s2, s0, s1
    	// CHECK: btrue s2, .LBB0_5
        // CHECK: xor s0, s0, s1
        // CHECK: goto .LBB0_4
    }

    // CHECK: .LBB0_1:
    // CHECK: load_32 s0, .LCPI0_0

    return count + 1;
    // CHECK: .LBB0_4:
    // CHECK: load_32 s1, .LCPI0_1
    // CHECK: add_f_mask v0, s0, v1, s1
    // CHECK: .LBB0_5:
    // CHECK: ret
}


