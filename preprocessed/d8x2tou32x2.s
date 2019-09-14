/*
 * Copyright (C) 2011, 2019 Alexander Nasonov.
 *
 * [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
 *
 * __m128i d8x2tou32x2(__m128i bcd);
 *
 * Convert two unpacked BCD to two u32 binary numbers.
 *
 * Note: In unpacked BCD (binary coded decimal), each
 * digit takes a whole byte (vs 4 bits in packed BCD).
 */

/*
 * Copyright (C) 2011, 2019 Alexander Nasonov.
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

.intel_syntax noprefix

/*
 * Code below is based on my old idea from Jan 2011.
 * 
 * It uses SWAR (SIMD Within A Register) to work with digits in parallel:
 *
 * int32_t d8toi(uint64_t x)
 * {
 *	// Step 1: work with bytes.
 * 	x = 10u * x + (x >> 8);
 * 	x &= UINT64_C(0x00ff00ff00ff00ff);
 *
 *	// Step 2: work with words.
 * 	x = 100u * x + (x >> 16);
 * 	x &= UINT64_C(0x0000ffff0000ffff);
 *
 *	// Step 3: work with dwords.
 * 	x = 10000u * x + (x >> 32);
 * 	x &= 0xffffffff;
 * 
 * 	return x;
 * }
 *
 * See also
 * http://www.0x80.pl/articles/simd-parsing-int-sequences.html
 */

.text; .align 16; .globl d8x2tou32x2; .type d8x2tou32x2,@function; d8x2tou32x2:;
	# Steps 1 and 2 of SWAR translate perfectly into AVX.
	vpmaddubsw xmm0,xmm0,XMMWORD PTR [d8x2tou32x2_x10]
	vpmaddwd xmm0,xmm0,XMMWORD PTR [d8x2tou32x2_x100]

	# Step 3 of SWAR: dwords from the previous step
	# are small enough to pack then back to words.
	vpackssdw xmm0,xmm0,xmm0
	vpmaddwd xmm0,xmm0,XMMWORD PTR [d8x2tou32x2_x1e4]

	ret
.size d8x2tou32x2, . - d8x2tou32x2

.data

.align 16
d8x2tou32x2_x10:  .byte 10, 1, 10, 1, 10, 1, 10, 1, 10, 1, 10, 1, 10, 1, 10, 1
d8x2tou32x2_x100: .short 100, 1, 100, 1, 100, 1, 100, 1
d8x2tou32x2_x1e4: .short 10000, 1, 10000, 1, 10000, 1, 10000, 1
