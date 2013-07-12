
def make_encoding(x):
	str = '['
	for y in range(4):
		if y != 0:
			str += ','
			
		str += hex(x & 0xff)
		x >>= 8

	str += ']'
	return str	

def make_a_instruction(fmt, opcode, dest, src1, src2, mask):
	print make_encoding((6 << 29) | (fmt << 26) | (opcode << 20) | (src2 << 15) 
		| (mask << 10) | (dest << 5) | src1)

# No mask form
def make_c_instruction(isLoad, op, offset, destSrc, ptr):
	print make_encoding((1 << 31) | (isLoad << 29) | (op << 25) | ((offset / 4) << 10)
		| (destSrc << 5) | ptr)

def make_e_instruction(op, offset, reg):
	print make_encoding((0xf << 28) | (op << 25) | ((offset / 4) << 10) | reg)

#make_a_instruction(5, 1, 13, 15, 16, 14)
#make_e_instruction(2, 0xffffc, 12) 
make_c_instruction(1, 4, 0, 1, 2)