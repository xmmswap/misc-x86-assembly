/*
 * Copyright (C) 2019 Alexander Nasonov.
 *
 * [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
 *
 * int hhmmss(__m128i);
 *
 * Convert "HH:MM:SS" string loaded into the low qword of
 * xmm0 to a number of seconds. Return -1 for invalid inputs.
 *
 * This file can be compiled on NetBSD with gcc. If you
 * use a different OS, you can compile preprocessed
 * hhmmss.s (lower case s) with gas and link with ld/gcc.
 */

/*
 * Copyright (C) 2019 Alexander Nasonov.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
 */

#include <machine/asm.h>

.intel_syntax noprefix

ENTRY(hhmmss)
	// Convert ascii hh:mm:ss to digits h h 0 m m 0 s s.
	vpxor    xmm0,xmm0,XMMWORD PTR [hhmmss_xor]

	// Shuffle digits to low bytes of words in xmm0.
	// High bytes are filled with zeroes from positions
	// 2 and 5.
	vpshufb  xmm0,xmm0,XMMWORD PTR [hhmmss_shuf]

	// Saturate invalid input.
	vpaddusw xmm1,xmm0,XMMWORD PTR [hhmmss_sat]

	// Calculate ss, 60*mm and two copies or 1800*hh.
	vpmaddwd xmm0,xmm0,XMMWORD PTR [hhmmss_mul]

	// Check that hh, mm and ss are in range 00:00:00-23:59:59
	// and saturate, if not.
	vpcmpgtd xmm2,xmm0,XMMWORD PTR [hhmmss_max]
	vpaddusw xmm1,xmm1,xmm2

	// Find any saturated words.
	vpcmpeqd xmm2,xmm2,xmm2
	vpcmpeqw xmm1,xmm1,xmm2
	vptest   xmm1,xmm1
	jne      1f

	// ss + 60*mm + 1800*hh + 1800*hh.
	vpshufd  xmm1,xmm0,0x4e
	vpaddd   xmm0,xmm1,xmm0
	vpshufd  xmm1,xmm0,0xe5
	vpaddd   xmm0,xmm1,xmm0

	vmovd    eax,xmm0
	ret
1:
	mov      eax,-1
	ret
END(hhmmss)

.data

.align 16
hhmmss_xor:  .byte '0', '0', ':', '0', '0', ':', '0', '0', 0, 0, 0, 0, 0, 0, 0, 0
hhmmss_shuf: .byte 0, 5, 1, 2, 0, 5, 1, 2, 3, 5, 4, 2, 6, 5, 7, 2
hhmmss_sat:  .short 65525, 65525, 65525, 65525, 65525, 65525, 65525, 65525
hhmmss_mul:  .short 18000, 1800, 18000, 1800, 600, 60, 10, 1
hhmmss_max:  .int 41400, 41400, 3540, 59
