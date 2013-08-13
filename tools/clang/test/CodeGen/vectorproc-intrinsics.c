// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));
typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

int test_strand()	// CHECK: test_strand:
{
	return __builtin_vp_get_current_strand();
	// CHECK: getcr s{{[0-9]+}}, 0
}

veci16 test_gatherloadi(veci16 ptr) 	// CHECK: test_gatherloadi
{
	return __builtin_vp_gather_loadi(ptr);

	// CHECK: load.gath v{{[0-9]+}}, (v0)
}

vecf16 test_gatherloadf(veci16 ptr) 	// CHECK: test_gatherloadf
{
	return __builtin_vp_gather_loadf(ptr);

	// CHECK: load.gath v{{[0-9]+}}, (v0)
}

veci16 test_gatherloadi_masked(veci16 ptr, int mask) // CHECK: test_gatherloadi_masked
{
	return __builtin_vp_gather_loadi_masked(ptr, mask);

	// CHECK: load.gath.mask v{{[0-9]+}}, s0, (v0)
}

vecf16 test_gatherloadf_masked(veci16 ptr, int mask) // CHECK: test_gatherloadf_masked
{
	return __builtin_vp_gather_loadf_masked(ptr, mask);

	// CHECK: load.gath.mask v{{[0-9]+}}, s0, (v0)
}

void test_scatter_storei(veci16 ptr, veci16 value) // CHECK: test_scatter_storei
{
	__builtin_vp_scatter_storei(ptr, value);

	// CHECK: store.scat v1, (v0)
}

void test_scatter_storef(veci16 ptr, vecf16 value) // CHECK: test_scatter_storef
{
	__builtin_vp_scatter_storef(ptr, value);

	// CHECK: store.scat v1, (v0)
}

void test_scatter_storei_masked(veci16 ptr, veci16 value, int mask) // CHECK: test_scatter_storei_masked
{
	__builtin_vp_scatter_storei_masked(ptr, value, mask);

	// CHECK: store.scat.mask v1, s0, (v0)
}

void test_scatter_storef_masked(veci16 ptr, vecf16 value, int mask) // CHECK: test_scatter_storef_masked
{
	__builtin_vp_scatter_storef_masked(ptr, value, mask);

	// CHECK: store.scat.mask v1, s0, (v0)
}

veci16 test_block_loadi_masked(veci16 *ptr, int mask)	// CHECK: test_block_loadi_masked:
{
	return __builtin_vp_block_loadi_masked(ptr, mask);

	// CHECK: load.v.mask v{{[0-9]+}}, s1, (s0)
}

vecf16 test_block_loadf_masked(veci16 *ptr, int mask)	// CHECK: test_block_loadf_masked:
{
	return __builtin_vp_block_loadf_masked(ptr, mask);

	// CHECK: load.v.mask v{{[0-9]+}}, s1, (s0)
}

void test_block_storei_masked(veci16 *ptr, veci16 value, int mask) // CHECK: test_block_storei_masked:
{
	__builtin_vp_block_storei_masked(ptr, value, mask);

	// CHECK: store.v.mask v0, s1, (s0)
}

void test_block_storef_masked(veci16 *ptr, vecf16 value, int mask) // CHECK: test_block_storef_masked:
{
	__builtin_vp_block_storef_masked(ptr, value, mask);
	
	// CHECK: store.v.mask v0, s1, (s0)
}

int test_clz(int value)	// CHECK: test_clz
{
	return __builtin_clz(value);
	
	// CHECK: clz s0, s0
}

int test_ctz(int value)	// CHECK: test_ctz
{
	return __builtin_ctz(value);
	
	// CHECK: ctz s0, s0
}

int test_masked_cmpi_uge(veci16 a, veci16 b)	// CHECK: test_masked_cmpi_uge:
{
	return __builtin_vp_mask_cmpi_uge(a, b);
	// CHECK: setge.u s{{[0-9]+}}, v0, v1
}

int test_masked_cmpi_sge(veci16 a, veci16 b)	// CHECK: test_masked_cmpi_sge:
{
	return __builtin_vp_mask_cmpi_sge(a, b);
	// CHECK: setge.i s{{[0-9]+}}, v0, v1
}

int test_masked_cmpf_ge(vecf16 a, vecf16 b)	// CHECK: test_masked_cmpf_ge:
{
	return __builtin_vp_mask_cmpf_ge(a, b);
	// CHECK: setge.f s{{[0-9]+}}, v0, v1
}


