
// 20-bit branch offset
.global far1
far1 = 0x200ffc

// A bit too large for 20-bit offset
.global far2
far2 = 0x201004

// 25 bit branch offset.
.global far3
far3 = 0x4000ffc

// Too big for a 25 bit branch field
.global far4
far4 = 0x4001004

// Full 32-bit value
.global far5
far5 = 0xe756d28a
