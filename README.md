This is a toolchain for an an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). 
It includes a C/C++ compiler, assembler, and linker based on the LLVM, clang, and mclinker projects. 

## Building

### Requirements
- gcc 4.7+ or Apple clang 4.2+
- cmake 2.8.8
- python 2.7
- libxml (including headers)
- zlib (including headers)
- bison 2.7+
- flex 2.5+

On Ubuntu, these can be installed by using: 

    sudo apt-get install libxml2-dev cmake gcc g++ python bison flex zlib1g-dev  

On MacOS, I'd recommend installing a package manager like MacPorts (https://www.macports.org/) to install/upgrade these. Most of the libraries should already be installed by default, but Apple likes their command line utilities... finely aged... so many will be out of date and won't work.

### Compiling

Assuming the proper packages are installed, configure and build using the following commands. 

<pre>
> mkdir build
> cd build
> cmake ..
> make
> sudo make install
</pre>

A few other things to note:

* The name of the target is 'vectorproc'.
* There are also bits of an autoconf based build system in this project.  It doesn't work.
* The toolchain will be installed to /usr/local/llvm-vectorproc
* Using sudo on make install as described can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R &#x60;whoami&#x60; .' in the build directory will fix this.
* If you want to make changes to the compiler, add '-DCMAKE_BUILD_TYPE=Debug' as a parameter to the cmake command enable a debug build.  This enables the -debug flag for command line tools, which is important to see various transormations and output of intermediate passes.


## Invoking compiler

Once built, the toolchain will be installed into /usr/local/llvm-vectorproc

    /usr/local/llvm-vectorproc/bin/clang -o program.elf test_program.c 

## Running tests

* Change PATH environment variable to include the binary directory (build/bin) 
* the test can be run as follows (assuming you are at the top of the project directory)

<pre>
    llvm-lit test
    llvm-lit tools/clang/test/CodeGen/vectorproc*
</pre>

## Running whole program tests

There are a set of tests in https://github.com/jbush001/GPGPU/tree/master/tests/compiler
Each test case is compiled and then run in the instruction set simulator.
The output is checked for validity. This is similar to the test-suite project
in LLVM. Instructions are found in that directory.ls
sudo
