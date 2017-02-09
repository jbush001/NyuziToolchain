// RUN: spmd-compile %s -o - -S | FileCheck %s

float f(float count)
{
    float i;
    float sum = 0;

    for (i = 0; i < count; i++) {
        // CHECK: .LBB0_2:
        sum = sum + i;
        // CHECK: add_f_mask
        // CHECK: add_f_mask
        // CHECK: cmplt_f
        // CHECK: btrue s{{[0-9]+}}, .LBB0_2
    }

    // CHECK: .LBB0_3:
    return sum;
    // CHECK: move_mask
    // CHECK: ret
}

