// RUN: spmd-compile %s -S -o - | FileCheck %s

float gcd(float a, float b)
{
	while (a != b)
	{
    	// CHECK: cmpne_f s1, v0, v1
    	// CHECK: bfalse s1, .LBB0_6
        // CHECK: goto .LBB0_2

		if (a > b) {
			a = a - b;
		} else {
			b = b - a;
        }

        // The then and else clauses are reordered above
        // %elsebody:
        // CHECK: .LBB0_5:
        // CHECK: sub_f_mask v1, s1, v1, v0
        // %looptop
        // CHECK: .LBB0_1:
        // CHECK: cmpne_f s1, v0, v1
        // CHECK: bfalse s1, .LBB0_6
        // %loopbody
        // CHECK: .LBB0_2:
        // CHECK: cmpgt_f s2, v0, v1
        // CHECK: and s3, s2, s1
        // CHECK: bfalse s3, .LBB0_4
        // CHECK: sub_f_mask v0, s3, v0, v1
        // % elsetop
        // CHECK: .LBB0_4:
        // CHECK: xor s2, s2, -1
        // CHECK: and s1, s1, s2
        // CHECK: and s1, s1, s0
        // CHECK: bfalse s1, .LBB0_1
        // CHECK: goto .LBB0_5
	}

    // CHECK: .LBB0_6:
    // CHECK: ret

	return a;
}
