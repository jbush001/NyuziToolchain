// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef int veci16_t __attribute__((ext_vector_type(16)));
typedef float vecf16_t __attribute__((ext_vector_type(16)));

veci16_t test_vaddi(veci16_t a, veci16_t b)	// CHECK: test_vaddi:
{
	return a + b;
	// CHECK: add_i v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}
}

vecf16_t test_vaddf(vecf16_t a, vecf16_t b)	// CHECK: test_vaddf:
{
	return a + b;
	// CHECK: add_f v{{[0-9]+}}, v{{[0-9]+}}, v{{[0-9]+}}
}

// Note: the following two will probably unroll loops and use the immediate form of getlane

int sum_lanesi(veci16_t a)	// CHECK: sum_lanesi:
{
	int sum = 0;

	for (int index = 0; index < 16; index++)
	{
		sum += a[index];
		// CHECK: getlane s{{[0-9]+}}, v0,
	}

	return sum;
}

float sum_lanesf(vecf16_t a)	// CHECK: sum_lanesf:
{
	float sum = 0;

	for (int index = 0; index < 16; index++)
	{
		sum += a[index];
		// CHECK: getlane s{{[0-9]+}}, v0,
	}

	return sum;
}

veci16_t vector_scalari(veci16_t a, int b)	// CHECK: vector_scalari:
{
	return a + b;

	// CHECK: add_i v0, v0, s0
}

vecf16_t vector_scalarf(vecf16_t a, float b)	// CHECK: vector_scalarf:
{
	return a + b;

	// CHECK: add_f v0, v0, s0
}


veci16_t vector_scalar_const(veci16_t a)	// CHECK: vector_scalar_const:
{
	return a + 12;

	// CHECK: add_i v0, v0, 12
}

veci16_t vector_setfieldi(veci16_t a, int lane)	// CHECK: vector_setfieldi:
{
	a[lane]++;

	// CHECK: move_mask v{{[0-9]+}},

	return a;
}

vecf16_t vector_setfieldf(vecf16_t a, int lane)	// CHECK: vector_setfieldf:
{
	a[lane]++;

	// CHECK: move_mask v{{[0-9]+}},

	return a;
}


