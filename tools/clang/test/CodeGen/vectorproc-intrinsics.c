// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

int test_strand()	// CHECK: test_strand:
{
	return __builtin_vp_get_current_strand();
	// CHECK: s{{[0-9]+}} = cr0
}



