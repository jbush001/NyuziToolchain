// RUN: %clang_cc1 -triple nyuzi-none-none -emit-llvm -o - %s | FileCheck %s

typedef int veci16 __attribute__((__vector_size__(16 * sizeof(int))));

int sdata;
veci16 vdata;

void test_load_32() {
  asm("load_32 $1, %0" :: "m"(sdata));
  // CHECK: call void asm sideeffect "load_32 $$1, $0", "*m"(i32* @sdata)
}

void test_load_vector() {
  asm("load_v $1, %0" :: "m"(vdata));
  // CHECK: call void asm sideeffect "load_v $$1, $0", "*m"(<16 x i32>* @vdata)
}

unsigned int test_scalar_register_op(unsigned int a, unsigned int b)
{
    unsigned int result;

    // r and s constraints are equivalent, test both
    asm("add_i $0, $1, $2" : "=r" (result) : "r" (a), "r" (b));

    // CHECK: call i32 asm "add_i $$0, $$1, $$2", "=r,r,r"(i32 %0, i32 %1)

    return result;
}

veci16 test_vector_register_op(veci16 a, veci16 b)
{
    veci16 result;

    // r and s constraints are equivalent, test both
    asm("add_i $0, $1, $2" : "=v" (result) : "v" (a), "v" (b));

  // CHECK: call <16 x i32> asm "add_i $$0, $$1, $$2", "=v,v,v"(<16 x i32> %0, <16 x i32> %1)

    return result;
}

