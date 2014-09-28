// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

float test_div(float a, float b)	// CHECK: test_div:
{
	return a / b;
	// CHECK: reciprocal s{{[0-9]+}}, s1
}

float test_recip(float a)		// CHECK: test_recip
{
	return 1.0 / a;
	// CHECK: reciprocal s{{[0-9]+}}, s0
}

vecf16 test_vdiv(vecf16 a, vecf16 b)	// CHECK: test_vdiv:
{
	return a / b;
	// CHECK: reciprocal v{{[0-9]+}}, v1
}

vecf16 test_vrecip(vecf16 a)		// CHECK: test_vrecip
{
	return __builtin_nyuzi_makevectorf(1.0) / a;
	// CHECK: reciprocal v{{[0-9]+}}, v0
}
