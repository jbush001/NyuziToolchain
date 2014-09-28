# RUN: llvm-mc -filetype=obj -triple nyuzi-elf %s -o - | \
# RUN: llvm-objdump -section-headers -t - | FileCheck  %s

        load_32 s0, foo  # CHECK: ELF32-nyuzi
        
        
# This test ensures the assembler doesn't assert with unresolved data references
