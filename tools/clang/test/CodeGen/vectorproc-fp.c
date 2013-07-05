// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

float test_div(float a, float b)	// CHECK: test_div:
{
	return a / b;
	// CHECK: f{{[0-9]+}} = reciprocal(f1)
}

float test_recip(float a)		// CHECK: test_recip
{
	return 1.0 / a;
	// CHECK: f{{[0-9]+}} = reciprocal(f0)
}

vecf16 test_vdiv(vecf16 a, vecf16 b)	// CHECK: test_vdiv:
{
	return a / b;
	// CHECK: vf{{[0-9]+}} = reciprocal(vf1)
}

vecf16 test_vrecip(vecf16 a)		// CHECK: test_vrecip
{
	return __builtin_vp_makevectorf(1.0) / a;
	// CHECK: vf{{[0-9]+}} = reciprocal(vf0)
}
