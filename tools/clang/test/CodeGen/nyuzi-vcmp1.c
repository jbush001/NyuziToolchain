// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));

int subdivideTile(
	veci16 acceptStep1, 
	veci16 acceptStep2)
{
	int trivialAcceptMask = __builtin_nyuzi_mask_cmpi_sle(acceptStep1, __builtin_nyuzi_makevectori(0))
		& __builtin_nyuzi_mask_cmpi_sle(acceptStep2, __builtin_nyuzi_makevectori(0));

	// CHECK: cmple_i s{{[0-9]+}}, v{{[0-9]+}}
	// CHECK: cmple_i s{{[0-9]+}}, v{{[0-9]+}}
	// CHECK: and

	return trivialAcceptMask;
}
