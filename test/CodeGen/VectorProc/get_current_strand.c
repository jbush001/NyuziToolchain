// Test reading current strand ID

// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

int foo()
{
	return __builtin_vp_get_current_strand();
}

// CHECK: s{{[0-9]+}} = cr0
