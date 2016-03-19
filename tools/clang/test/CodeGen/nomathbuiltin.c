// RUN: %clang_cc1 -fno-math-builtin -emit-llvm -o - %s | FileCheck %s

// Fails on nyuzi because double is 32 bits wide, so unions aren't padded.
// XFAIL: nyuzi

// Check that the -fno-math-builtin option for -cc1 is working properly.


double pow(double, double);

double foo(double a, double b) {
  return pow(a, b);
// CHECK: call {{.*}}double @pow
}

