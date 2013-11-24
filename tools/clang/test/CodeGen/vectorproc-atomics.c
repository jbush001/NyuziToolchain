// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

int atomic_add(volatile int *lockvar)
{
	return __sync_fetch_and_and(lockvar, 1);

	// CHECK: [[LABEL:L[0-9A-Za-z_]+]]:
	// CHECK: load_sync [[SCRATCH1:s[0-9]+]], (s0)
	// CHECK: move {{s[0-9]+}}, [[SCRATCH1]]
	// CHECK: and [[SCRATCH2:s[0-9]+]], [[SCRATCH1]], 
	// CHECK: store_sync [[SCRATCH2]], (s0)	
	// CHECK: bfalse [[SCRATCH2]], [[LABEL]]
}

void stbar()
{
	__sync_synchronize();	// CHECK: membar
}

void atomic_cmp_swap(volatile int *lockvar)
{
	int old;
	do
	{
		 old = *lockvar;
	}
	while (__sync_val_compare_and_swap(lockvar, old, old + 1) != old);

	// [[LOOP1MBB:L[0-9A-Za-z_]+]]
	//   load_sync
	//   setne [[CMPRES:s[0-9]+]]
	//   btrue [[CMPRES]], [[EXITMBB]]
	// {{L[0-9A-Za-z_]+}}
	//   move [[SUCCESS:s[0-9]+]]
	//   store_sync [[SUCCESS]]
	//   bfalse [[SUCCESS]], [[LOOP1MBB]]
	// [[EXITMBB:L[0-9A-Za-z_]+]]
}