This compiler front-end demonstrates compiling a simple, c-like language
into single program, multiple data (SPMD) kernels. It parallelizes a
scalar program to run 16 instances in parallel, one in each vector lanes.
At places where control flow diverges, it uses mask registers to control
which lanes are updated.

This is currently not installed, but is copied to the build/bin directory.