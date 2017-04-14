// RUN: spmd-compile %s -S -o - | FileCheck %s

float returnstmt(float a, float count)
{
    if (a > count) {
        return a;
    }

    return count + 1;

    // CHECK: ret
}


