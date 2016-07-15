// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef float vecf16_t __attribute__((ext_vector_type(16)));

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

vecf16_t test_vdiv(vecf16_t a, vecf16_t b)	// CHECK: test_vdiv:
{
	return a / b;
	// CHECK: reciprocal v{{[0-9]+}}, v1
}

vecf16_t test_vrecip(vecf16_t a)		// CHECK: test_vrecip
{
	return 1.0 / a;
	// CHECK: reciprocal v{{[0-9]+}}, v0
}
