// RUN: spmd-compile %s -S -o - | FileCheck %s

float gcd(float a, float b)
{
	while (a != b)
	{
    	// CHECK: cmpne_f
    	// CHECK: bz s{{[0-9]+}}, [[LABEL6:\.LBB[0-9]_[0-9]+]]
        // CHECK: b [[LABEL2:\.LBB[0-9]_[0-9]+]]

		if (a > b) {
			a = a - b;
		} else {
			b = b - a;
        }

        // The then and else clauses are reordered above
        // CHECK: [[LABEL5:\.LBB[0-9]_[0-9]+]]:
        // CHECK: sub_f_mask
        // CHECK: [[LABEL1:\.LBB[0-9]_[0-9]+]]:
        // CHECK: cmpne_f
        // CHECK: bz s{{[0-9]+}}, [[LABEL6]]
        // CHECK: [[LABEL2]]:
        // CHECK: cmpgt_f
        // CHECK: and
        // CHECK: bz s{{[0-9]+}}, [[LABEL4:\.LBB[0-9]_[0-9]+]]
        // CHECK sub_f_mask
        // CHECK: [[LABEL4]]:
        // CHECK: xor
        // CHECK: and
        // CHECK: and
        // CHECK: bz s{{[0-9]+}}, [[LABEL1]]
        // CHECK: b [[LABEL5]]
	}

    // CHECK: [[LABEL6]]:
    // CHECK: ret

	return a;
}
