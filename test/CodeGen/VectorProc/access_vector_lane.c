// Test reading a specific element of a vector lane

// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

typedef int __vi16 __attribute__((__vector_size__(16 * sizeof(int))));

int sum_lanes(__vi16 *value)
{
	int sum = 0;
	
	for (int i = 0; i < 16; i++)
		sum += (*value)[i];
		
	return sum;
}

// CHECK: s{{[0-9]+}} = getfield(v{{[0-9]+}}, s{{[0-9]+}})
