// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s
// XFAIL: 

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(float))));

volatile int lockvar;

void atomic_add(volatile int *lockvar)
{
	while (__sync_fetch_and_and(lockvar, 1) != 0)
		;

	// CHECK: = mem_sync[
	// CHECK: mem_sync[
}
