This is a port of LLVM and the clang compiler an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). It's currently a work in progress and only partially functional.

## To build:

### Create a build directory outside the llvm/ directory (usually at the same level)

<pre>
mkdir build
cd build
</pre>

### Configure and build:
This requires a newer version of a compiler that supports c++11.
cmake must be installed (http://www.cmake.org/)
Note that -stdlib=libc++ is required on MacOS to pick up the correct libc.  This may differ on other platforms.
<pre>
cd build
cmake   -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGET_ARCH="VectorProc" ../llvm
make
</pre>

### To run compiler

<pre>
./bin/clang &lt;test_program.c&gt; -S -o -
</pre>

## Running unit tests

* Switch to *build* directory and cd into test/.  Type 'make'.  This will set up
the configuration (it will try to run a bunch of tests, a bunch of which will fail.  
It's okay to Ctrl-C at this point).
* Same deal with clang.  From the top of the build directory, switch to tools/clang/test and
type 'make'.
* Change PATH environment variable to include the binary directory (build/Debug+Asserts/bin) 
* From the top of the source (not build) directory, run:

<pre>
  llvm-lit test/CodeGen/VectorProc
  llvm-lit test/MC/VectorProc
  llvm-lit tools/clang/test/CodeGen/vectorproc*
</pre>

## To view DAGs graphically

* Make sure GraphViz is in PATH.  Run configure and build.
* Generate LLVM IR code for source file:

<pre>
build/bin/clang -target vectorproc branch.c -emit-llvm  -o branch.llvm -S
</pre>

* Run llc on the code to view the output:

<pre>
build/bin/llc -view-dag-combine1-dags branch.llvm 
</pre>

The following options are legal:

* -view-dag-combine1-dags displays the DAG after being built, before the first optimization pass.
* -view-legalize-dags displays the DAG before Legalization.
* -view-dag-combine2-dags displays the DAG before the second optimization pass.
* -view-isel-dags displays the DAG before the Select phase.
* -view-sched-dags displays the DAG before Scheduling.


