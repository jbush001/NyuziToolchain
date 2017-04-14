// RUN: spmd-compile %s -S -o - | FileCheck %s

float gcd(float a, float b)
{
	while (a != b)
	{

		if (a > b) {
			a = a - b;
		} else {
			b = b - a;
        }


	}

    // CHECK: ret

	return a;
}
