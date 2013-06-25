// Test conditional branch and comparisons

// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

int max(int a, int b)
{
	if (a > b)
		return a;
	else
		return b;
}

// CHECK: s[[CHECKVAL:[0-9]+]] = s{{[0-9]+}} <= s{{[0-9]+}}
// CHECK: if s[[CHECKVAL]] goto [[FALSELABEL:[A-Z0-9_]+]]
// CHECK: goto {{[A-Z0-9_]+}}
// CHECK: [[FALSELABEL]]:


