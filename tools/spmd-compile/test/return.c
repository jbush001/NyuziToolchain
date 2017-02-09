// RUN: spmd-compile %s -S -o - | FileCheck %s

float returnstmt(float a, float count)
{
    if (a > count) {
    	// CHECK: cmpgt_f

        // Early out if no lanes match
    	// CHECK: bfalse s{{[0-9]+}}, [[LABEL1:\.LBB[0-9]_[0-9]+]]
        return a;

        // CHECK: move_mask
    	// CHECK: load_32
    	// CHECK: and
    	// CHECK: cmpeq_i
    	// CHECK: btrue s{{[0-9]+}}, [[LABEL2:\.LBB[0-9]_[0-9]+]]
        // CHECK: xor
        // CHECK: goto [[LABEL3:\.LBB[0-9]_[0-9]+]]
    }

    // CHECK: [[LABEL1]]

    return count + 1;
    // CHECK: [[LABEL3]]
    // CHECK: load_32
    // CHECK: add_f_mask
    // CHECK: [[LABEL2]]
    // CHECK: ret
}


