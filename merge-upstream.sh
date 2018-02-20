#!/bin/bash

git checkout upstream
rm -rf .clang-tidy .clang-format .arcconfig *

BASE_URL=http://llvm.org/svn/llvm-project
SVNREV="$(svn info --show-item=revision $BASE_URL)"
svn co $BASE_URL/llvm/trunk@$SVNREV .
svn co $BASE_URL/cfe/trunk@$SVNREV tools/clang
svn co $BASE_URL/lldb/trunk@$SVNREV tools/lldb
svn co $BASE_URL/lld/trunk@$SVNREV tools/lld
svn co $BASE_URL/compiler-rt/trunk@$SVNREV runtimes/compiler-rt

find . -type d -name .svn -exec rm -rf {} \;
find . -type f -name .gitignore -delete
git add --all .

git commit -a -m "Pull latest code from upstream llvm, lld, lldb, cfe, compiler-rt @$SVNREV"
git checkout master
git merge upstream --no-commit --no-ff

# Show list of conflicts
git diff --name-only --diff-filter=U
