#!/bin/bash

git checkout upstream
rm -rf .clang-format .arcconfig *

SVNREV="$(svn info http://llvm.org/svn/llvm-project/llvm/trunk | grep Revision: | awk -F ' ' '{print $2}')"
svn co http://llvm.org/svn/llvm-project/llvm/trunk@$SVNREV .
svn co http://llvm.org/svn/llvm-project/cfe/trunk@$SVNREV tools/clang
svn co http://llvm.org/svn/llvm-project/lldb/trunk@$SVNREV tools/lldb
svn co http://llvm.org/svn/llvm-project/lld/trunk@$SVNREV tools/lld

find . -type d -name .svn -exec rm -rf {} \;
find . -type f -name .gitignore -delete
git add --all .

git commit -a -m "Pull latest code from upstream llvm, lld, lldb, cfe @$SVNREV"
git checkout master
git merge upstream

# Show list of conflicts
git diff --name-only --diff-filter=U
