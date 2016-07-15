// RUN: %clang_cc1 -triple nyuzi-none-none -emit-llvm -o - %s | FileCheck %s

typedef int veci16_t __attribute__((ext_vector_type(16)));


int sdata;
veci16_t vdata;

int test_load_32() {
  int result;

  asm("load_32 %0, %1" : "=s"(result) : "m"(sdata));
  // CHECK: call i32 asm "load_32 $0, $1", "=s,*m"(i32* @sdata)

  return result;
}

veci16_t test_load_vector() {
  veci16_t result;

  asm("load_v %0, %1" : "=v"(result) : "m"(vdata));
  // CHECK: call <16 x i32> asm "load_v $0, $1", "=v,*m"(<16 x i32>* @vdata)

  return result;
}

unsigned int test_scalar_register_op(unsigned int a, unsigned int b)
{
    unsigned int result;

    // r and s constraints are equivalent, test both
    asm("add_i %0, %1, %2" : "=r" (result) : "r" (a), "r" (b));

    // CHECK: call i32 asm "add_i $0, $1, $2", "=r,r,r"(i32 %0, i32 %1)

    return result;
}

veci16_t test_vector_register_op(veci16_t a, veci16_t b)
{
    veci16_t result;

    // r and s constraints are equivalent, test both
    asm("add_i %0, %1, %2" : "=v" (result) : "v" (a), "v" (b));

  // CHECK: call <16 x i32> asm "add_i $0, $1, $2", "=v,v,v"(<16 x i32> %0, <16 x i32> %1)

    return result;
}

