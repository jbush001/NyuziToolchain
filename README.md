This is a port of LLVM and the clang compiler to the VectorProc architecture.

To build:

1. Create a build directory outside the llvm/ directory (usually at the same level)

mkdir build
cd build

2. Configure and build:

cd build
../llvm/configure --enable-targets=vectorproc
make

To run (from within build directory)

./Debug+Asserts/bin/clang -target vectorproc &lt;test program&gt; -S -o -


