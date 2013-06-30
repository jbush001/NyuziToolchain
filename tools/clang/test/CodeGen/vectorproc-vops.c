// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));


veci16 test_vadd(veci16 a, veci16 b)	// CHECK: test_vadd:
{
	return a + b;
	// CHECK: v{{[0-9]+}} = v0 + v1
}

int sum_lanes(veci16 a)	// CHECK: sum_lanes:
{
	int sum = 0;
	
	for (int index = 0; index < 16; index++)
	{
		sum += a[index];
		// CHECK: s{{[0-9]+}} = getfield(v0, s{{[0-9]+}})
	}

	return sum;
}

veci16 vector_scalar(veci16 a, int b)	// CHECK: vector_scalar:
{
	return a + __builtin_vp_makevectori(b);
	
	// CHECK: v0 = v0 + s0
}

veci16 vector_scalar_const(veci16 a)	// CHECK: vector_scalar_const
{
	return a + __builtin_vp_makevectori(12);
	// CHECK: v0 = v0 + 12
}


