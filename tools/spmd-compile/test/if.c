// RUN: spmd-compile %s -S -o - | FileCheck %s

float ifstmt(float a, float b)
{
    // CHECK: load_32

    float retval = 0;
	if (a > 0) {
        // CHECK: cmpgt_f
        // CHECK: bz s{{[0-9]+}}, [[LABEL1:\.LBB[0-9]_[0-9]+]]
        retval = a - b;
    	// CHECK: move
    	// CHECK: sub_f_mask
    	// CHECK: load_32
    	// CHECK: and
    	// CHECK: cmpeq_i
    	// CHECK: bnz s{{[0-9]+}}, [[LABEL2:\.LBB[0-9]_[0-9]+]]
    	// CHECK: xor
    	// CHECK: b [[LABEL3:\.LBB[0-9]_[0-9]+]]
	} else {
        // CHECK: [[LABEL1]]
        // CHECK: move
        // CHECK: [[LABEL3]]
        // CHECK: move_mask
        retval = b;
    }

    // CHECK: [[LABEL2]]
    // CHECK: load_32
    // CHECK: move_mask
    // CHECK: ret

    return retval;
}

