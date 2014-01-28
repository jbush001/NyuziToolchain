# RUN: llvm-mc -filetype=obj -triple vectorproc-elf %s -o - | \
# RUN: llvm-objdump -section-headers -t - | FileCheck  %s

        load_32 s0, foo  # CHECK: ELF32-vectorproc
        
        
# This test ensures the assembler doesn't assert with unresolved data references