// RUN: spmd-compile %s -S -o - | FileCheck %s

float ifstmt(float a, float b)
{
    float retval = 0;
	if (a > 0) {
        retval = a - b;
	} else {
        retval = b;
    }

    // CHECK: ret

    return retval;
}

