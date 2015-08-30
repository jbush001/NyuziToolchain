This is a toolchain for a parallel processor architecture called
[Nyuzi](https://github.com/jbush001/NyuziProcessor), based on
[LLVM](http://llvm.org/).  It includes a C/C++ compiler (clang), assembler,
linker and debugger (lldb).

While this project includes a C/C++ compiler, the LLVM backend can support
any language.  There is a small, experimental SPMD parallel compiler in
tools/spmd_compiler.

Questions or issues can be directed to the [mailing list](https://groups.google.com/forum/#!forum/nyuzi-processor-dev) or...   
[![Chat at https://gitter.im/jbush001/NyuziProcessor](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jbush001/NyuziProcessor?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


# Building

The NyuziProcessor repository README has instructions for building this as
well. These instructions are only necessary if you want to build this
separately.

## Required Software

The following sections describe how to install these packages.

- gcc 4.8+ or Apple clang 4.2+
- cmake 2.8.12+
- python 2.7
- libxml (including headers)
- zlib (including headers)
- bison 2.7+
- flex 2.5+
- swig (http://www.swig.org/) with python wrappers
- libedit (http://thrysoee.dk/editline/)
- ncurses

## Building on Linux 

You can install required packages using the built-in package manager (apt-get,
yum, etc). As LLVM needs newer versions of many packages, you should be on
a recent version of your Linux distribution. Instructions are below are for Ubuntu
(which must be on at least version 14). You may need to change the package names
for other distributions:

    sudo apt-get install libxml2-dev cmake gcc g++ python bison flex zlib1g-dev swig python-dev libedit-dev ncurses-dev

    git clone git@github.com:jbush001/NyuziToolchain.git
    cd NyuziToolchain
    mkdir build
    cd build
    cmake ..
    make
    sudo make install

## Building on MacOS

On Mavericks and later, you can install the host command line compiler like this:

    xcode-select --install

On earlier versions, you can download XCode from the app store. You will also
need to install a package manager like [MacPorts](https://www.macports.org/) to
get the remaining dependencies. Open a new terminal to do the build after
installing MacPorts, because it installs alternate versions of some utilities
and updates the PATH. Once you have done this:

    sudo port install cmake bison swig swig-python

    git clone https://github.com/jbush001/NyuziToolchain.git
    cd NyuziToolchain
    mkdir build
    cd build
    cmake ..
    make
    sudo make install
    
**Upgrading 'flex' using the package manager may cause build errors. I
would recommend using the system supplied version.**

## Building on Windows

I have not tested this natively on Windows. Many of the libraries are already cross 
platform, so it should theoretically be possible.

## Other Notes

* The toolchain is installed into /usr/local/llvm-nyuzi/
* The triple for this target is 'nyuzi-'.
* There are also bits of an autoconf based build system in this project.  It doesn't work.
* Using sudo on make install as described leaves files with root ownership in
  the build directory. This causes cryptic build errors later when building as
  non-root. Doing 'sudo chown -R &#x60;whoami&#x60; .' in the build directory
  will fix this.

## Running Regression Tests

Change PATH environment variable to include the binary directory (build/bin). This is only required 
for llvm-lit based tests. Run the tests as follows (assuming you are at the top of the project 
directory):

```
export PATH=<BUILDDIR>/build/bin:$PATH
llvm-lit test
llvm-lit tools/clang/test/CodeGen/nyuzi*
```

All tests should pass.

## Running Whole Program Tests

There is a set of tests in
https://github.com/jbush001/NyuziProcessor/tree/master/tests/compiler Each test
case is compiled and then run in the instruction set simulator, which checks
the output for validity. This is similar to the test-suite project in LLVM.
Instructions are in that directory.

