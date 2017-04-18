# RUN: llvm-mc -arch=nyuzi %s | FileCheck %s

# Ensure parser properly handles complex expressions

move s0, (1 << 5) | (1 << 7) # CHECK: move s0, 160

.set FOO, 121
move s1, FOO ^ 1  # CHECK move s1, 120

