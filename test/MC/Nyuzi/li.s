# RUN: llvm-mc -arch=nyuzi %s | FileCheck %s

        li s0, 0        # CHECK: move s0, 0

        # Largest positive constant that will fit in a move instruction
        li s1, 8191     # CHECK: move s1, 8191

        # Requires only a movehi because low bits aren't set
        li s3, 8192     # CHECK: movehi s3, 1
                        # CHECK-NOT: or s3

        # movehi/or to set low bits
        li s4, 8193     # CHECK: movehi s4, 1
                        # CHECK: or s4, s4, 1

        # Largest 32-bit positive constant
        li s5, 2147483647   # CHECK: movehi s5, 262143
                            # CHECK: or s5, s5, 8191

        # Largest negative constant that will fit in move instruction
        li s2, -8192     # CHECK: move s2, -8192

        # Negative, only requirest movehi
        li s6, -16384       # CHECK: movehi s6, 524286
                            # CHECK-NOT: or s6

        # Negative, requires movehi/or
        li s7, -16385       # CHECK: movehi s7, 524285
                            # CHECK: or s7, s7, 8191

        # Largest 32-bit negative constant
        li s8, -2147483648  # CHECK: movehi s8, 262144
                            # CHECK-NOT: or s8

        # Arbitrary value
        li s9, 0xdeadbeef   # CHECK: movehi s9, 456045
                            # CHECK: or s9, s9, 7919

        # Expression
        li s10, (1 << 13) | 1   # CHECK: movehi s10, 1
                                # CHECK: or s10, s10, 1
