// RUN: spmd-compile %s -o - -S | FileCheck %s

float f(float count)
{
    float i;
    float sum = 0;

    for (i = 0; i < count; i++) {
        // CHECK: .LBB0_2:
        sum = sum + i;
        // CHECK: add_f_mask v1, s0, v1, v2
        // CHECK: add_f_mask v2, s0, v2, s1
        // CHECK: cmplt_f s0, v2, v0
        // CHECK: btrue s0, .LBB0_2
    }

    // CHECK: .LBB0_3:
    return sum;
    // CHECK: move_mask v0, s0, v1
    // CHECK: ret
}

