This is a port of LLVM and the clang compiler an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). 

## To build:

### Create a build directory within the llvm/ directory

<pre>
mkdir build
cd build
</pre>

### Configure and build:
This requires a newer version of a compiler that supports c++11.
cmake must be installed (http://www.cmake.org/). 
* Note that there is also an autoconf based build system in the directory.  They won't work, because lld specifically is cmake only.
* MAKE_INSTALL_PREFIX will put this in a different path than the default compiler.  Since this only builds for VectorProc, be careful not to overwrite your system compiler.

__MacOS__
<pre>
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" -DLLVM_DEFAULT_TARGET_TRIPLE=vectorproc ..
make
make install
</pre>

__Linux/GCC__
<pre>
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++0x" -DLLVM_DEFAULT_TARGET_TRIPLE=vectorproc ..
make
make install
</pre>

### To run compiler

<pre>
/usr/local/llvm-vectorproc/clang -c &lt;test_program.c&gt; 
/usr/local/llvm-vectorproc/lld -flavor gnu -target vectorproc  -static &lt;test_program.o&gt;
</pre>

## Running unit tests

* Switch to *build* directory and cd into test/.  Type 'make check'.  This will set up
the configuration (it will try to run a bunch of tests, a bunch of which will fail.  It's okay to Ctrl-C at this point).
* Same deal with clang.  From the top of the build directory, switch to tools/clang/test and
type 'make check'.
* Change PATH environment variable to include the binary directory (build/Debug+Asserts/bin) 
* From the top of the source (not build) directory, run:

<pre>
  llvm-lit test/CodeGen/VectorProc
  llvm-lit test/MC/VectorProc
  llvm-lit tools/clang/test/CodeGen/vectorproc*
</pre>

## Running whole program tests

There are a set of tests in https://github.com/jbush001/GPGPU/tree/master/tests/compiler
Each test case is compiled and then run in the instruction set simulator.
The output is checked for validity. This is similar to the test-suite project
in LLVM.
