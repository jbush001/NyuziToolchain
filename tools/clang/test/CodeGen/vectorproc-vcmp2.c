// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));
typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

veci16 cmpi(veci16 a, veci16 b)	// CHECK: cmpi:
{
	return a > b;
	// CHECK: setgt_i [[MASKREG:s[0-9]+]]
	// CHECK: move_mask v{{[0-9]+}}, [[MASKREG]]
}

veci16 cmpf(vecf16 a, vecf16 b)	// CHECK: cmpf:
{
	return a > b;
	// CHECK: setgt_f [[MASKREG:s[0-9]+]]
	// CHECK: move_mask v{{[0-9]+}}, [[MASKREG]]
}
