This compiler is currently not copied to /usr/local/... by the install target, but
is available in NyuziToolchain/build/bin.  It reads a program from stdin and dumps
the LLVM IR and assembly output to stdout. The programs use a C-like syntax. Here
is an example:

    float gcd(float a, float b)
    {
        while (a != b)
        {
            if (a > b)
                a = a - b;
            else
                b = b - a;
        }

        return a;
    }

This can be compiled like this:

    NyuziToolchain/build/bin/spmd-compile < gcd.k
