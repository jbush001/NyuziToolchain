This is a port of LLVM and the clang compiler to an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). 

## Building:
* This requires a newer version of a compiler that supports c++11.  Upgrade your compiler if necessary.
* cmake must be installed. This is available for most Linux distros and can be installed automatically using the standard package manager (apt-get, yum, etc).  Sources are available here:  http://www.cmake.org/

Create a build directory from within the top level directory of this project:
<pre>
> mkdir build
> cd build
</pre>

Configure:

__MacOS__
<pre>
> cmake -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" -DLLVM_DEFAULT_TARGET_TRIPLE=vectorproc ..
</pre>

__Linux/GCC__
<pre>
> cmake -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++0x" -DLLVM_DEFAULT_TARGET_TRIPLE=vectorproc ..
</pre>

Build and install
<pre>
> make
> sudo make install
</pre>

A few other things to note:

* There is also an autoconf based build system in the directory.  They won't work, because a number of tools only have cmake configurations.
* MAKE_INSTALL_PREFIX will put this in a different path than the default compiler.  Since this only builds for VectorProc, this is important to avoid overwriting the system compiler (on a Mac, which uses clang as the system compiler).
* It will probably be necessary to add 'sudo' to the beginning of make install. However, this can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R &#x60;whoami&#x60; .' in the build directory can fix this.

### Invoking compiler

The toolchain will be installed into /usr/local/llvm-vectorproc

<pre>
/usr/local/llvm-vectorproc/bin/clang -o program.elf test_program.c 
</pre>

## Running unit tests

* From the shell, switch to the directory build/test/.  Type 'make check'.  This will set up
the configuration (it will try to run a bunch of tests, many of which will fail.  It's okay to Ctrl-C at this point).
* Do the same thing for clang.  From the top of the build directory, switch to tools/clang/test and type 'make check'.
* Change PATH environment variable to include the binary directory (build/bin) 
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
in LLVM. Instructions are found in that directory.
