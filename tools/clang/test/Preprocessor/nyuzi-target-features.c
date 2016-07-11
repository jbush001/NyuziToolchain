// RUN: %clang -target nyuzi-elf-none -x c -E -dM %s -o - | FileCheck %s

// CHECK: #define __BYTE_ORDER__ __ORDER_LITTLE_ENDIAN__
// CHECK: #define __LITTLE_ENDIAN__ 1
// CHECK-NOT: #define __BIG_ENDIAN__ 1
// CHECK: #define __NYUZI__ 1
// CHECK: #define __SIZEOF_DOUBLE__ 4
// CHECK: #define __SIZEOF_FLOAT__ 4
// CHECK: #define __SIZEOF_INT__ 4
// CHECK: #define __SIZEOF_LONG__ 4
// CHECK: #define __SIZEOF_POINTER__ 4
