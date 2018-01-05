# RUN: llvm-mc -triple nyuzi-elf %s | FileCheck  %s

# Emit instructions that access all registers to ensure they are
# configured properly.

add_i s0, s1, s2
add_i s3, s4, s5
add_i s6, s7, s8
add_i s9, s10, s11
add_i s12, s13, s14
add_i s15, s16, s17
add_i s18, s19, s20
add_i s21, s22, s23
add_i s24, s25, s26
add_i s27, gp, fp
add_i sp, ra, s0

# CHECK: add_i s0, s1, s2
# CHECK: add_i s3, s4, s5
# CHECK: add_i s6, s7, s8
# CHECK: add_i s9, s10, s11
# CHECK: add_i s12, s13, s14
# CHECK: add_i s15, s16, s17
# CHECK: add_i s18, s19, s20
# CHECK: add_i s21, s22, s23
# CHECK: add_i s24, s25, s26
# CHECK: add_i s27, gp, fp
# CHECK: add_i sp, ra, s0

load_32 s0, (s1)
load_32 s2, (s3)
load_32 s27, (s27)

# CHECK: load_32 s0, (s1)
# CHECK: load_32 s2, (s3)
# CHECK: load_32 s27, (s27)
