// RUN: spmd-compile %s -o - -S | FileCheck %s

float f(float count)
{
    float i;
    float sum = 0;

    for (i = 0; i < count; i++) {
        sum = sum + i;
    }

    return sum;
    // CHECK: ret
}

