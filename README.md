This is a toolchain for an an experimental GPGPU architecture (https://github.com/jbush001/GPGPU), including a C/C++ compiler, assembler, and linker, based on the LLVM compiler infrastructure and clang compiler. 

## Building
* This requires a host compiler that supports c++11.  Upgrade if necessary.
* cmake 2.8.8 or newer must be installed. This is available for most Linux distros and can be installed automatically using the standard package manager (apt-get, yum, etc).  Sources are available here:  http://www.cmake.org/

Configure and build using the following commands
<pre>
> mkdir build
> cd build
> cmake ..
> make
> sudo make install
</pre>

A few other things to note:

* There is also an autoconf based build system in this project.  It doesn't work.
* Using sudo on make install as described can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R &#x60;whoami&#x60; .' in the build directory will fix this.
* If you are building on a multi-core machine, use 'make -j <i>n</i>' to do a faster parallel build, where <i>n</i> is the number of cores.
* If you want to hack on the compiler, enable a debug build by replacing the cmake command above with 'cmake -DCMAKE_BUILD_TYPE=Debug ..'.  This enables the -debug flag for command line tools, which is important to see various transormations and output of intermediate passes.

### Invoking compiler

The toolchain will be installed into /usr/local/llvm-vectorproc

<pre>
/usr/local/llvm-vectorproc/bin/clang -o program.elf test_program.c 
</pre>

## Running unit tests

* From the shell, switch to the directory build/test/.  Type 'make check'.  This will set up
the configuration (it will try to run a bunch of tests, many of which will fail.  It's okay to Ctrl-C at this point).  
* Do the same thing for clang.  From the top of the build directory, switch to tools/clang/test and type 'make check'. These two steps only need to be done once when setting up the project for the first time.
* Change PATH environment variable to include the binary directory (build/bin) 
* From the top of the source (not build) directory, the test can be run as follows:

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
