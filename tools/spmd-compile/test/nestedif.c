// RUN: spmd-compile %s -S -o - | FileCheck %s

float nestedif(float a, float b)
{
    float retval = 0;

	if (a > b) {
		if (a > 0) {
            retval = a - b;
		} else {
            retval = b;
        }
	} else {
		if (b > 0) {
            retval = b - a;
		} else {
            retval = a;
        }
    }

    return retval;
}

// CHECK: 	ret


