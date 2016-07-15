// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef int veci16_t __attribute__((ext_vector_type(16)));
typedef float vecf16_t __attribute__((ext_vector_type(16)));

veci16_t cmpi(veci16_t a, veci16_t b)	// CHECK: cmpi:
{
	return a > b;
	// CHECK: cmpgt_i [[MASKREG:s[0-9]+]]
	// CHECK: move_mask v{{[0-9]+}}, [[MASKREG]]
}

veci16_t cmpf(vecf16_t a, vecf16_t b)	// CHECK: cmpf:
{
	return a > b;
	// CHECK: cmpgt_f [[MASKREG:s[0-9]+]]
	// CHECK: move_mask v{{[0-9]+}}, [[MASKREG]]
}
