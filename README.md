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
* Note that there is also a 'configure' script in the directory.  It doesn't work, because lld specifically is cmake only.
* -stdlib=libc++ is required on MacOS to pick up the correct libc.  This may differ on other platforms.
* MAKE_INSTALL_PREFIX will put this in a different path than the default compiler.  Since this only builds for VectorProc, be careful not to overwrite your system compiler.

<pre>
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/llvm-vectorproc/ -DLLVM_TARGETS_TO_BUILD="VectorProc" -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++"  -DLLVM_TARGET_ARCH="VectorProc" ../llvm
make
</pre>

### To run compiler

<pre>
./bin/clang -target vectorproc &lt;test_program.c&gt; -S -o -
</pre>

Or

<pre>
/usr/local/llvm-vectorproc/clang -c -integrated-as -target vectorproc &lt;test_program.c&gt; 
/usr/local/llvm-vectorproc/ lld -flavor gnu -target vectorproc  -static &lt;test_program.o&gt;
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


