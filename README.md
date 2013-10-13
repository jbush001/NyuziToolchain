This is a port of LLVM and the clang compiler to an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). 

## To build:

### Create a build directory within the llvm/ directory

<pre>
mkdir build
cd build
</pre>

### Configure and build:
* This requires a newer version of a compiler that supports c++11.  Upgrade your compiler.
* cmake must be installed.  On Linux, apt-get or yum can install this automatically.  Sources are available here:  http://www.cmake.org/

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

A few other things to note:
* There is also an autoconf based build system in the directory.  They won't work, because lld specifically is cmake only.
* MAKE_INSTALL_PREFIX will put this in a different path than the default compiler.  Since this only builds for VectorProc, this is important to avoid overwriting the system compiler (on a Mac, which uses clang as the system compiler).
* It will probably be necessary to add 'sudo' to the beginning of make install. However, this can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R `whoami` .' in the build directory can fix this.
* clang is statically linked and the link phase uses a lot of memory.  If you don't have enough virtual memory, the build may fail with the message 'ld terminated with signal 9'.  Adding -DCMAKE_BUILD_TYPE=Release as one of the parameters on the cmake command line above may help with this.

### To run compiler

<pre>
/usr/local/llvm-vectorproc/clang -c &lt;test_program.c&gt; 
/usr/local/llvm-vectorproc/lld -flavor gnu -static &lt;test_program.o&gt;
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
