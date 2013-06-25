This is a port of LLVM and the clang compiler an experimental GPGPU architecture (https://github.com/jbush001/GPGPU). It's currently a work in progress and only partially functional.

To build:

1. Create a build directory outside the llvm/ directory (usually at the same level)

<pre>
mkdir build
cd build
</pre>

2. Configure and build:

<pre>
cd build
../llvm/configure --enable-targets=vectorproc
make
</pre>

To run (from within build directory)

<pre>
./Debug+Asserts/bin/clang -target vectorproc &lt;test_program.c&gt; -S -o -
</pre>

3. Running tests

* Put the output binaries (build/Debug+Asserts/bin) directory in your path
* From the top of the source directory, run:

<pre>
  llvm-lit test/CodeGen/VectorProc
</pre>

4. To view DAGs:

* Make sure GraphViz is in your path.  Run configure and build.
* Generate LLVM IR code for your file:

<pre>
./Debug+Asserts/bin/clang  -target vectorproc branch.c -emit-llvm  -o branch.llvm -S
</pre>

* Run llc on the code to view the output:

<pre>
./Debug+Asserts/bin/llc -view-dag-combine1-dags branch.llvm 
</pre>

The following options are legal:

* -view-dag-combine1-dags displays the DAG after being built, before the first optimization pass.
* -view-legalize-dags displays the DAG before Legalization.
* -view-dag-combine2-dags displays the DAG before the second optimization pass.
* -view-isel-dags displays the DAG before the Select phase.
* -view-sched-dags displays the DAG before Scheduling.


