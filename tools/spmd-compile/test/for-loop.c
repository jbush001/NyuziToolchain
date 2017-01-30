// RUN: spmd-compile %s -o - -S | FileCheck %s

float f(float count)
{
    float i;
    float sum = 0;

    for (i = 0; i < count; i++) {
        // CHECK: .LBB0_2:
        sum = sum + i;
        // CHECK: add_f_mask v3, s1, v3, s0
        // CHECK: add_f_mask v1, s1, v1, v2
        // CHECK: cmplt_f s1, v2, v0
        // CHECK: bfalse s1, .LBB0_3
        // CHECK: goto .LBB0_2
    }

    // CHECK: .LBB0_3:
    return sum;
    // CHECK: 	ret
}

