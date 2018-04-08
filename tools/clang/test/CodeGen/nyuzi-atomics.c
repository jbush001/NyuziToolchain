// RUN: %clang %s -O3 -target nyuzi -S -o - | FileCheck %s

// CHECK: atomic_add:
int atomic_add(volatile int *lockvar)
{
	return __sync_fetch_and_and(lockvar, 1);

	// CHECK: load_sync [[SCRATCH1:s[0-9]+]], (s0)
	// CHECK-DAG: move {{s[0-9]+}}, [[SCRATCH1]]
	// CHECK-DAG: and [[SCRATCH2:s[0-9]+]], [[SCRATCH1]],
	// CHECK: store_sync [[SCRATCH2]], (s0)
	// CHECK: bz [[SCRATCH2]],
}

// CHECK: stbar:
void stbar()
{
	__sync_synchronize();	// CHECK: membar
}

// CHECK: atomic_cmp_swap:
void atomic_cmp_swap(volatile int *lockvar)
{
	int old;

	do
	{
		 old = *lockvar;
	}
	while (__sync_val_compare_and_swap(lockvar, old, old + 1) != old);

	// CHECK:   load_sync
	// CHECK:   cmpne_i [[CMPRES:s[0-9]+]]
	// CHECK:   bnz [[CMPRES]],

	// CHECK:   move [[SUCCESS:s[0-9]+]]
	// CHECK:   store_sync [[SUCCESS]]
	// CHECK:   bz [[SUCCESS]],
}

// CHECK: atomic_test_set:
void atomic_test_set(volatile int *lockvar)
{
	while (!__sync_lock_test_and_set(lockvar, 1))
		;

    // CHECK: move [[SCRATCH1:s[0-9]+]], 1
    // CHECK: [[LABEL:\.LBB[0-9]_[0-9]]]
	// CHECK: load_sync [[SCRATCH2:s[0-9]+]], (s0)
	// CHECK: move [[SCRATCH3:s[0-9]+]], [[SCRATCH1]]
	// CHECK: store_sync [[SCRATCH3]], (s0)
	// CHECK: bz [[SCRATCH3]], [[LABEL]]
}
