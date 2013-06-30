// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));
typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

veci16 test_vaddi(veci16 a, veci16 b)	// CHECK: test_vaddi:
{
	return a + b;
	// CHECK: v{{[0-9]+}} = v0 + v1
}

vecf16 test_vaddf(vecf16 a, vecf16 b)	// CHECK: test_vaddf:
{
	return a + b;
	// CHECK: vf{{[0-9]+}} = vf0 + vf1
}

int sum_lanesi(veci16 a)	// CHECK: sum_lanesi:
{
	int sum = 0;
	
	for (int index = 0; index < 16; index++)
	{
		sum += a[index];
		// CHECK: s{{[0-9]+}} = getfield(v0, s{{[0-9]+}})
	}

	return sum;
}

float sum_lanesf(vecf16 a)	// CHECK: sum_lanesf:
{
	float sum = 0;
	
	for (int index = 0; index < 16; index++)
	{
		sum += a[index];
		// CHECK: f{{[0-9]+}} = getfield(vf0, s{{[0-9]+}})
	}

	return sum;
}

veci16 vector_scalari(veci16 a, int b)	// CHECK: vector_scalari:
{
	return a + __builtin_vp_makevectori(b);
	
	// CHECK: v0 = v0 + s0
}

vecf16 vector_scalarf(vecf16 a, float b)	// CHECK: vector_scalarf:
{
	return a + __builtin_vp_makevectorf(b);
	
	// CHECK: vf0 = vf0 + f0
}


veci16 vector_scalar_const(veci16 a)	// CHECK: vector_scalar_const:
{
	return a + __builtin_vp_makevectori(12);
	// CHECK: v0 = v0 + 12
}

veci16 vector_setfieldi(veci16 a, int lane)	// CHECK: vector_setfieldi:
{
	a[lane]++;
	
	// CHECK: [[ONE:s[0-9]+]] = 1
	// CHECK: [[MASK:s[0-9]+]] = [[ONE]] << s0
	// CHECK: v{{[0-9]+}}{[[MASK]]} = 

	return a;
}

vecf16 vector_setfieldf(vecf16 a, int lane)	// CHECK: vector_setfieldf:
{
	a[lane]++;

	// CHECK: [[ONE:s[0-9]+]] = 1
	// CHECK: [[MASK:s[0-9]+]] = [[ONE]] << s0
	// CHECK: vf{{[0-9]+}}{[[MASK]]} = 

	return a;
}


