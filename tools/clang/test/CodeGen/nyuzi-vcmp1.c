// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef int veci16_t __attribute__((ext_vector_type(16)));

int subdivideTile(
	veci16_t acceptStep1,
	veci16_t acceptStep2)
{
	int trivialAcceptMask = __builtin_nyuzi_mask_cmpi_sle(acceptStep1, (veci16_t) 0)
		& __builtin_nyuzi_mask_cmpi_sle(acceptStep2, (veci16_t) 0);

	// CHECK: cmple_i s{{[0-9]+}}, v{{[0-9]+}}
	// CHECK: cmple_i s{{[0-9]+}}, v{{[0-9]+}}
	// CHECK: and

	return trivialAcceptMask;
}
