// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s
// XFAIL: 

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(float))));

volatile veci16 lockvar;

void atomic_add(volatile veci16 *lockvar)
{
	while (__sync_fetch_and_and(&lockvar, 1) != 0)
		;

	; CHECK: = mem_sync[
	; CHECK: mem_sync[
}
