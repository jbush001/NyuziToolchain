// RUN: spmd-compile %s -S -o - | FileCheck %s

float gcd(float a, float b)
{
	while (a != b)
	{
		if (a > b)
			a = a - b;
		else
			b = b - a;
	}

	return a;
}

// CHECK: gcd:
// CHECK: .LBB0_5:
// CHECK: 	sub_f_mask v1, s0, v1, v0
// CHECK: .LBB0_1:
// CHECK: 	cmpne_f s0, v0, v1
// CHECK: 	bfalse s0, .LBB0_6
// CHECK: 	cmpgt_f s1, v0, v1
// CHECK: 	and s2, s1, s0
// CHECK: 	bfalse s2, .LBB0_4
// CHECK: 	sub_f_mask v0, s2, v0, v1
// CHECK: .LBB0_4:
// CHECK: 	xor s1, s1, -1
// CHECK: 	and s0, s1, s0
// CHECK: 	bfalse s0, .LBB0_1
// CHECK: 	goto .LBB0_5
// CHECK: .LBB0_6:
// CHECK: 	ret
