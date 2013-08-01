// RUN: %clang %s -O3 -target vectorproc -S -o - | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));

void fillMasked(int mask);

void subdivideTile(
	int acceptCornerValue1, 
	int acceptCornerValue2, 
	veci16 acceptStep1, 
	veci16 acceptStep2)
{
	veci16 acceptEdgeValue1;
	veci16 acceptEdgeValue2;
	int trivialAcceptMask;

	// Compute accept masks
	acceptEdgeValue1 = acceptStep1 + __builtin_vp_makevectori(acceptCornerValue1);
	trivialAcceptMask = __builtin_vp_mask_cmpi_sle(acceptEdgeValue1, __builtin_vp_makevectori(0));
	acceptEdgeValue2 = acceptStep2 + __builtin_vp_makevectori(acceptCornerValue2);
	trivialAcceptMask &= __builtin_vp_mask_cmpi_sle(acceptEdgeValue2, __builtin_vp_makevectori(0));

	// End recursion
	fillMasked(trivialAcceptMask);
	return;
}
