# RUN: not llvm-mc -filetype=obj -triple nyuzi-elf  %s -o /dev/null 2>&1 | FileCheck  %s

flargbh s0, s1, s2  # CHECK: unrecognized-mnemonic.s:[[@LINE]]:{{[0-9]+}}: error: invalid instruction

# Check that it suggests properly when the mnemonic is close
load_33 s0, (s1)    # CHECK: unrecognized-mnemonic.s:[[@LINE]]:{{[0-9]+}}: error: invalid instruction, did you mean: load_32?
ad_i s0, s1, s2     # CHECK: unrecognized-mnemonic.s:[[@LINE]]:{{[0-9]+}}: error: invalid instruction, did you mean: add_i?
subb_i s0, s1, s2    # CHECK: unrecognized-mnemonic.s:[[@LINE]]:{{[0-9]+}}: error: invalid instruction, did you mean: sub_i?

