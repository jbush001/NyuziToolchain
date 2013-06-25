// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

// Test addition of vectors

typedef int __vi16 __attribute__((__vector_size__(16 * sizeof(int))));

int main()
{
	__vi16 a;
	__vi16 b;
	__vi16 c;

	a = b + c;
}

// CHECK: v{{[0-9]+}} = v{{[0-9]+}} + v{{[0-9]+}}
