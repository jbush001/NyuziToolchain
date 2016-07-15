// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef int veci16_t __attribute__((ext_vector_type(16)));
typedef float vecf16_t __attribute__((ext_vector_type(16)));

int test_write_control_reg(int value)	// CHECK: test_write_control_reg:
{
	__builtin_nyuzi_write_control_reg(5, value);
	// CHECK: setcr s{{[0-9]+}}, 5
}

int test_read_control_reg(int value)	// CHECK: test_read_control_reg:
{
	return __builtin_nyuzi_read_control_reg(7);
	// CHECK: getcr s{{[0-9]+}}, 7
}


veci16_t test_gatherloadi(veci16_t ptr) 	// CHECK: test_gatherloadi
{
	return __builtin_nyuzi_gather_loadi(ptr);

	// CHECK: load_gath v{{[0-9]+}}, (v0)
}

vecf16_t test_gatherloadf(veci16_t ptr) 	// CHECK: test_gatherloadf
{
	return __builtin_nyuzi_gather_loadf(ptr);

	// CHECK: load_gath v{{[0-9]+}}, (v0)
}

veci16_t test_gatherloadi_masked(veci16_t ptr, int mask) // CHECK: test_gatherloadi_masked
{
	return __builtin_nyuzi_gather_loadi_masked(ptr, mask);

	// CHECK: load_gath_mask v{{[0-9]+}}, s0, (v0)
}

vecf16_t test_gatherloadf_masked(veci16_t ptr, int mask) // CHECK: test_gatherloadf_masked
{
	return __builtin_nyuzi_gather_loadf_masked(ptr, mask);

	// CHECK: load_gath_mask v{{[0-9]+}}, s0, (v0)
}

void test_scatter_storei(veci16_t ptr, veci16_t value) // CHECK: test_scatter_storei
{
	__builtin_nyuzi_scatter_storei(ptr, value);

	// CHECK: store_scat v1, (v0)
}

void test_scatter_storef(veci16_t ptr, vecf16_t value) // CHECK: test_scatter_storef
{
	__builtin_nyuzi_scatter_storef(ptr, value);

	// CHECK: store_scat v1, (v0)
}

void test_scatter_storei_masked(veci16_t ptr, veci16_t value, int mask) // CHECK: test_scatter_storei_masked
{
	__builtin_nyuzi_scatter_storei_masked(ptr, value, mask);

	// CHECK: store_scat_mask v1, s0, (v0)
}

void test_scatter_storef_masked(veci16_t ptr, vecf16_t value, int mask) // CHECK: test_scatter_storef_masked
{
	__builtin_nyuzi_scatter_storef_masked(ptr, value, mask);

	// CHECK: store_scat_mask v1, s0, (v0)
}

veci16_t test_block_loadi_masked(veci16_t *ptr, int mask)	// CHECK: test_block_loadi_masked:
{
	return __builtin_nyuzi_block_loadi_masked(ptr, mask);

	// CHECK: load_v_mask v{{[0-9]+}}, s1, (s0)
}

vecf16_t test_block_loadf_masked(veci16_t *ptr, int mask)	// CHECK: test_block_loadf_masked:
{
	return __builtin_nyuzi_block_loadf_masked(ptr, mask);

	// CHECK: load_v_mask v{{[0-9]+}}, s1, (s0)
}

void test_block_storei_masked(veci16_t *ptr, veci16_t value, int mask) // CHECK: test_block_storei_masked:
{
	__builtin_nyuzi_block_storei_masked(ptr, value, mask);

	// CHECK: store_v_mask v0, s1, (s0)
}

void test_block_storef_masked(veci16_t *ptr, vecf16_t value, int mask) // CHECK: test_block_storef_masked:
{
	__builtin_nyuzi_block_storef_masked(ptr, value, mask);

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

int test_masked_cmpi_uge(veci16_t a, veci16_t b)	// CHECK: test_masked_cmpi_uge:
{
	return __builtin_nyuzi_mask_cmpi_uge(a, b);
	// CHECK: cmpge_u s{{[0-9]+}}, v0, v1
}

int test_masked_cmpi_sge(veci16_t a, veci16_t b)	// CHECK: test_masked_cmpi_sge:
{
	return __builtin_nyuzi_mask_cmpi_sge(a, b);
	// CHECK: cmpge_i s{{[0-9]+}}, v0, v1
}

int test_masked_cmpf_ge(vecf16_t a, vecf16_t b)	// CHECK: test_masked_cmpf_ge:
{
	return __builtin_nyuzi_mask_cmpf_ge(a, b);
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
	// CHECK: move s0, ra
}


