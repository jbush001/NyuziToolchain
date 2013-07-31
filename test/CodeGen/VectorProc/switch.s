	.file	"switch.ll"
	.text
	.globl	foo
	.align	4
	.type	foo,@function
foo:                                    ; @foo
; BB#0:                                 ; %entry
	sub.i sp, sp, 64
	store.32 fp, 60(sp)             ; 2-byte Folded Spill
	move fp, sp
	setgt.u s2, s0, 3
	btrue s2, LBB0_6
; BB#1:                                 ; %entry
	shl s0, s0, 2
	load.32 s2, LCPI0_0
	add.i s0, s0, s2
	load.32 s0, (s0)
	goto s0
LBB0_2:                                 ; %sw.bb
	add.i s1, s1, 1
	goto LBB0_6
LBB0_3:                                 ; %sw.bb1
	mul.i s1, s1, 7
	goto LBB0_6
LBB0_4:                                 ; %sw.bb2
	mul.i s1, s1, s1
	goto LBB0_6
LBB0_5:                                 ; %sw.bb4
	add.i s0, s1, -1
	shl s1, s1, s0
LBB0_6:                                 ; %return
	move s0, s1
	load.32 fp, 60(sp)              ; 2-byte Folded Reload
	add.i sp, sp, 64
	ret
Ltmp0:
	.size	foo, Ltmp0-foo
	.section	.rodata,"a",@progbits
	.align	4
LJTI0_0:
	.word	LBB0_2
	.word	LBB0_3
	.word	LBB0_4
	.word	LBB0_5


