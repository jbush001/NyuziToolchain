
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

make_a_instruction(5, 1, 13, 15, 16, 14)