This is a toolchain for an an experimental GPGPU architecture (https://github.com/jbush001/GPGPU), including a C/C++ compiler, assembler, and linker, based on the LLVM compiler infrastructure and clang compiler. 

## Building

### Requirements
- cmake 2.8.8
- libxml
- python 2.7
- gcc 4.7+ or Apple clang 4.2+

On Ubuntu, these can be installed by using: sudo apt-get install libxml2-dev cmake gcc g++ python.  You must be on at least release 12.10.

On MacOS, you'll need to either use a package manager like MacPorts, or download cmake manually and (http://cmake.org/) build it.  The other dependencies should already be installed.

__Upgrading/installing toolchain on MacOS__

<i>I did this with Lion; newer versions may or may not be different.</i>

- Download XCode from the App Store app, if not already installed (but you're not done yet...)
- Launch the XCode GUI.  Select the XCode menu from the menu bar and click 'Preferences'.  Highlight the 'Downloads' icon.  Make sure the 'Components' tab is selected.  Click the 'Install' button next to Commnd Line Tools.

### Building

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
* Using sudo on make install as described can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R &#x60;whoami&#x60; .' in the build directory will fix this.
* If you are building on a multi-core machine, use 'make -j <i>n</i>' to do a faster parallel build, where <i>n</i> is the number of cores.
* If you want to make changes to the compiler, add '-DCMAKE_BUILD_TYPE=Debug' as a parameter to the cmake command enable a debug build.  This enables the -debug flag for command line tools, which is important to see various transormations and output of intermediate passes.

### Invoking compiler

Once built, the toolchain will be installed into /usr/local/llvm-vectorproc

    /usr/local/llvm-vectorproc/bin/clang -o program.elf test_program.c 

### Running tests

* Change PATH environment variable to include the binary directory (build/bin) 
* the test can be run as follows (assuming you are at the top of the project directory)

    llvm-lit test
    llvm-lit tools/clang/test/CodeGen/vectorproc*

Note that one test will fail in the LLVM test suite because of known limitations:
* CodeGen/Generic/2007-04-08-MultipleFrameIndices.ll

## Running whole program tests

There are a set of tests in https://github.com/jbush001/GPGPU/tree/master/tests/compiler
Each test case is compiled and then run in the instruction set simulator.
The output is checked for validity. This is similar to the test-suite project
in LLVM. Instructions are found in that directory.
