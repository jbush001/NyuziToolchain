This is a toolchain for an an experimental GPGPU architecture (https://github.com/jbush001/GPGPU), including a C/C++ compiler, assembler, and linker, based on the LLVM compiler infrastructure and clang compiler. 

## Building
* This requires a host compiler that supports c++11.  Upgrade if necessary (see notes below)
* cmake 2.8.8 or newer must be installed. This is available for most Linux distros and can be installed automatically using the standard package manager (apt-get, yum, etc).  Sources are available here:  http://www.cmake.org/

Assuming the proper packages are installed, configure and build using the following commands:
<pre>
> mkdir build
> cd build
> cmake ..
> make
> sudo make install
</pre>

A few other things to note:

* The name of the target is 'vectorproc'.
* There is also an autoconf based build system in this project.  It doesn't work.
* Using sudo on make install as described can leave files with root ownership in your build directory, which can then cause cryptic build errors later when building as non-root.  Doing a 'sudo chown -R &#x60;whoami&#x60; .' in the build directory will fix this.
* If you are building on a multi-core machine, use 'make -j <i>n</i>' to do a faster parallel build, where <i>n</i> is the number of cores.
* If you want to hack on the compiler, enable a debug build by replacing the cmake command above with 'cmake -DCMAKE_BUILD_TYPE=Debug ..'.  This enables the -debug flag for command line tools, which is important to see various transormations and output of intermediate passes.

### Building on Ubuntu 

Ubuntu doesn't seem to have the latest version of any of these packages. 

<b>cmake</b>
- Download lastest version (Unix/Linux source) from here http://www.cmake.org/cmake/resources/software.html
(cmake-2.8.12.2.tar.gz)
<pre>
tar xfvz &lt;cmake-xxxxx.tar.gz&gt;
cd cmake-<i>xxxx</i>
./configure
make 
make install
</pre>

<b>GCC
This requires at least gcc 4.7 (with C++11 support), which is not available via the normal install.  Here's how to get it:
<pre>
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-4.7 g++-4.7
</pre>

The libxml2 libraries also need to be installed
<pre>
sudo apt-get install libxml2-dev
</pre>

When running cmake in this case, you will need to explicitly specify the path to the compiler, replacing the cmake line above with:

<pre>
cmake -D CMAKE_C_COMPILER=/usr/bin/gcc-4.7 -D CMAKE_CXX_COMPILER=/usr/bin/g++-4.7 ..
</pre>

### Building on MacOS (Assuming Lion; newer version may or may not be different)

- First, download XCode from the App Store app, if you don't already have it.
- Launch the XCode GUI.  Select the XCode menu from the menu bar and click 'Preferences'.  Highlight the 'Downloads' icon.  Make sure the 'Components' tab is selected.  Click the 'Install' button next to Commnd Line Tools.

## Invoking compiler

The toolchain will be installed into /usr/local/llvm-vectorproc

<pre>
/usr/local/llvm-vectorproc/bin/clang -o program.elf test_program.c 
</pre>

## Running tests

* Change PATH environment variable to include the binary directory (build/bin) 
* the test can be run as follows (assuming you are at the top of the project directory)

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
