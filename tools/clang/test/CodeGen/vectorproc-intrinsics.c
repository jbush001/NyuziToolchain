// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));
typedef float vecf16 __attribute__((__vector_size__(16 * sizeof(float))));

int test_write_control_reg(int value)	// CHECK: test_write_control_reg:
{
	__builtin_vp_write_control_reg(5, value);
	// CHECK: setcr s{{[0-9]+}}, 5
}

int test_read_control_reg(int value)	// CHECK: test_read_control_reg:
{
	return __builtin_vp_read_control_reg(7);
	// CHECK: getcr s{{[0-9]+}}, 7
}


veci16 test_gatherloadi(veci16 ptr) 	// CHECK: test_gatherloadi
{
	return __builtin_vp_gather_loadi(ptr);

	// CHECK: load_gath v{{[0-9]+}}, (v0)
}

vecf16 test_gatherloadf(veci16 ptr) 	// CHECK: test_gatherloadf
{
	return __builtin_vp_gather_loadf(ptr);

	// CHECK: load_gath v{{[0-9]+}}, (v0)
}

veci16 test_gatherloadi_masked(veci16 ptr, int mask) // CHECK: test_gatherloadi_masked
{
	return __builtin_vp_gather_loadi_masked(ptr, mask);

	// CHECK: load_gath_mask v{{[0-9]+}}, s0, (v0)
}

vecf16 test_gatherloadf_masked(veci16 ptr, int mask) // CHECK: test_gatherloadf_masked
{
	return __builtin_vp_gather_loadf_masked(ptr, mask);

	// CHECK: load_gath_mask v{{[0-9]+}}, s0, (v0)
}

void test_scatter_storei(veci16 ptr, veci16 value) // CHECK: test_scatter_storei
{
	__builtin_vp_scatter_storei(ptr, value);

	// CHECK: store_scat v1, (v0)
}

void test_scatter_storef(veci16 ptr, vecf16 value) // CHECK: test_scatter_storef
{
	__builtin_vp_scatter_storef(ptr, value);

	// CHECK: store_scat v1, (v0)
}

void test_scatter_storei_masked(veci16 ptr, veci16 value, int mask) // CHECK: test_scatter_storei_masked
{
	__builtin_vp_scatter_storei_masked(ptr, value, mask);

	// CHECK: store_scat_mask v1, s0, (v0)
}

void test_scatter_storef_masked(veci16 ptr, vecf16 value, int mask) // CHECK: test_scatter_storef_masked
{
	__builtin_vp_scatter_storef_masked(ptr, value, mask);

	// CHECK: store_scat_mask v1, s0, (v0)
}

veci16 test_block_loadi_masked(veci16 *ptr, int mask)	// CHECK: test_block_loadi_masked:
{
	return __builtin_vp_block_loadi_masked(ptr, mask);

	// CHECK: load_v_mask v{{[0-9]+}}, s1, (s0)
}

vecf16 test_block_loadf_masked(veci16 *ptr, int mask)	// CHECK: test_block_loadf_masked:
{
	return __builtin_vp_block_loadf_masked(ptr, mask);

	// CHECK: load_v_mask v{{[0-9]+}}, s1, (s0)
}

void test_block_storei_masked(veci16 *ptr, veci16 value, int mask) // CHECK: test_block_storei_masked:
{
	__builtin_vp_block_storei_masked(ptr, value, mask);

	// CHECK: store_v_mask v0, s1, (s0)
}

void test_block_storef_masked(veci16 *ptr, vecf16 value, int mask) // CHECK: test_block_storef_masked:
{
	__builtin_vp_block_storef_masked(ptr, value, mask);
	
	// CHECK: store_v_mask v0, s1, (s0)
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
	// CHECK: cmpge_u s{{[0-9]+}}, v0, v1
}

int test_masked_cmpi_sge(veci16 a, veci16 b)	// CHECK: test_masked_cmpi_sge:
{
	return __builtin_vp_mask_cmpi_sge(a, b);
	// CHECK: cmpge_i s{{[0-9]+}}, v0, v1
}

int test_masked_cmpf_ge(vecf16 a, vecf16 b)	// CHECK: test_masked_cmpf_ge:
{
	return __builtin_vp_mask_cmpf_ge(a, b);
	// CHECK: cmpge_f s{{[0-9]+}}, v0, v1
}

unsigned int test_builtin_frame_address() // CHECK: test_builtin_frame_address:
{
	return __builtin_frame_address(0);
	// CHECK: add_i sp, sp, -
	// CHECK: store_32 fp, 
	// CHECK: move fp, sp
	// CHECK: move s0, fp
}

unsigned int test_builtin_return_address() // CHECK: test_builtin_return_address:
{
	return __builtin_return_address(0);	
	// CHECK: move s0, link
}


