// Floating point conversion

// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

int i;
float g;

void test()
{
	g = i;
}

// CHECK: f{{[0-9]+}} = s{{[0-9]}}

