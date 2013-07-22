// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s
// XFAIL:


typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));
typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

vecf16 conversion(veci16 i)
{
	return (vecf16) i;
	// CHECK: itof
}