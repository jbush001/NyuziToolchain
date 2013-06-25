// Test reading and writing global variables

// RUN: clang -target vectorproc -S %s -o - | FileCheck %s

int foo = 12;
int bar = 13;

void baz()
{
	bar = foo + 1;
}

// CHECK: s[[FOOPTR:[0-9]+]] = &foo
// CHECK: s[[FOOVAL:[0-9]+]] = mem_l[s[[FOOPTR]]]
// CHECK: s[[FOOVAL]] = s[[FOOVAL]] + 1
// CHECK: s[[BARPTR:[0-9]+]] = &bar
// CHECK: mem_l[s[[BARPTR]]] = s[[FOOVAL]]
