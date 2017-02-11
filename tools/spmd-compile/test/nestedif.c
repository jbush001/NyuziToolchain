// RUN: spmd-compile %s -S -o - | FileCheck %s

float nestedif(float a, float b)
{
    float retval = 0;

	if (a > b) {
		if (a > 0) {
            retval = a - b;
		} else {
            retval = b;
        }
	} else {
		if (b > 0) {
            retval = b - a;
		} else {
            retval = a;
        }
    }

    return retval;
}

// CHECK: 	cmpgt_f
// CHECK: 	bz s{{[0-9]+}}, [[LABEL1:\.LBB[0-9]_[0-9]+]]
// CHECK: 	cmpgt_f
// CHECK: 	and
// CHECK: 	bz s{{[0-9]+}}, [[LABEL3:\.LBB[0-9]_[0-9]+]]
// CHECK: 	move
// CHECK: 	sub_f_mask
// CHECK: 	b [[LABEL11:\.LBB[0-9]_[0-9]+]]
// CHECK: [[LABEL1]]:
// CHECK: 	move
// CHECK: 	b [[LABEL5:\.LBB[0-9]_[0-9]+]]
// CHECK: [[LABEL3]]:
// CHECK: 	move
// CHECK: [[LABEL11]]:
// CHECK: 	xor
// CHECK: 	and
// CHECK: 	and
// CHECK: 	bz s{{[0-9]+}}, [[LABEL4:\.LBB[0-9]_[0-9]+]]
// CHECK: 	move_mask
// CHECK: [[LABEL4]]:
// CHECK: 	xor
// CHECK: 	bz s{{[0-9]+}}, [[LABEL9:\.LBB[0-9]_[0-9]+]]
// CHECK: [[LABEL5]]:
// CHECK: 	cmpgt_f
// CHECK: 	and
// CHECK: 	bz s{{[0-9]+}}, [[LABEL7:\.LBB[0-9]_[0-9]+]]
// CHECK: 	sub_f_mask
// CHECK: [[LABEL7]]:
// CHECK: 	xor
// CHECK: 	and
// CHECK: 	bz s{{[0-9]+}}, [[LABEL9]]
// CHECK: 	move_mask
// CHECK: [[LABEL9]]:
// CHECK: 	move_mask
// CHECK: 	ret


