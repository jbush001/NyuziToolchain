// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

int atomic_add(volatile int *lockvar)
{
	return __sync_fetch_and_and(lockvar, 1);

	// CHECK: [[LABEL:L[0-9A-Za-z_]+]]:
	// CHECK: load.sync [[SCRATCH1:s[0-9]+]], (s0)
	// CHECK: move {{s[0-9]+}}, [[SCRATCH1]]
	// CHECK: and [[SCRATCH2:s[0-9]+]], [[SCRATCH1]], 
	// CHECK: store.sync [[SCRATCH2]], (s0)	
	// CHECK: bfalse [[SCRATCH2]], [[LABEL]]
}

void stbar()
{
	__sync_synchronize();	// CHECK: membar
}