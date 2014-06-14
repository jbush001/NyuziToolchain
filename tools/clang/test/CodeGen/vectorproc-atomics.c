// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

// CHECK: atomic_add:
int atomic_add(volatile int *lockvar)
{
	return __sync_fetch_and_and(lockvar, 1);

	// CHECK: [[LABEL:\.L[0-9A-Za-z_]+]]:
	// CHECK: load_sync [[SCRATCH1:s[0-9]+]], (s0)
	// CHECK: move {{s[0-9]+}}, [[SCRATCH1]]
	// CHECK: and [[SCRATCH2:s[0-9]+]], [[SCRATCH1]], 
	// CHECK: store_sync [[SCRATCH2]], (s0)	
	// CHECK: bfalse [[SCRATCH2]], [[LABEL]]
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

	do	// CHECK: {{\.L[0-9A-Za-z_]+}}
	{
		 old = *lockvar;
	}
	while (__sync_val_compare_and_swap(lockvar, old, old + 1) != old);

	// CHECK: [[LOOP1MBB:\.L[0-9A-Za-z_]+]]
	// CHECK:   load_sync
	// CHECK:   setne_i [[CMPRES:s[0-9]+]]
	// CHECK:   btrue [[CMPRES]], [[EXITMBB:\.L[0-9A-Za-z_]+]]

	// CHECK:   move [[SUCCESS:s[0-9]+]]
	// CHECK:   store_sync [[SUCCESS]]
	// CHECK:   bfalse [[SUCCESS]], [[LOOP1MBB]]
	// CHECK: [[EXITMBB]]
}

// CHECK: atomic_test_set:
void atomic_test_set(volatile int *lockvar)
{
	while (!__sync_lock_test_and_set(lockvar, 1))
		;

	// CHECK: load_sync [[SCRATCH1:s[0-9]+]], (s0)
	// CHECK: move {{s[0-9]+}}, [[SCRATCH1]]
	// CHECK: store_sync [[SCRATCH1]], (s0)	
	// CHECK: bfalse [[SCRATCH1]], {{\.L[0-9A-Za-z_]+}}
}