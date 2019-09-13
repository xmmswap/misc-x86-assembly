/*
 * Copyright (C) 2018 Alexander Nasonov.
 *
 * [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
 *
 * char *u32toa(char *out, uint32_t n);
 *
 * This function converts @n to a string and copies it to @out.
 * It returns a position of a terminating NUL character (but
 * doesn't write the NUL to it).
 *
 * You need a modern cpu which supports vpshufb instruction
 * and which doesn't slow down on overlapping writes.
 *
 * This file can be compiled on NetBSD with gcc. If you
 * use a different OS, you can compile preprocessed
 * u32toa.s (lower case s) with gas and link with ld/gcc.
 *
 * The code doesn't have much comments at the moment but main
 * ideas are all published.
 *
 * The main primitive is madd block for printing 4 digits with
 * leading zeroes. I wrote it in 2016:
 * @nasonov
 * https://gist.github.com/alnsn/83ae6391c66bc1f117b9b6b5fbf2c331
 *
 * Vlad Krasnov @thecomp1ler was involved in early discussions and
 * he had some interesting ideas. AFAIK, none of them are published.
 *
 * Printing short 1-2 digit numbers is based on Paul Huong's work:
 *
 * @pkhuong
 * https://pvk.ca/Blog/2017/12/22/appnexus-common-framework-its-out-also-how-to-print-integers-faster/
 * https://github.com/appnexus/acf/blob/master/src/an_itoa.c
 * https://gist.github.com/pkhuong/a545b5dc072ee4050948c1910b58a014
 *
 * See also Peter Cawley's posts:
 *
 * @corsix
 * http://www.corsix.org/content/converting-nine-digit-integers-to-strings
 * http://www.corsix.org/content/converting-floats-to-strings-part-1
 *
 * TODO
 * Evaluate VPDPWSSD from AVX512_VNNI instruction set when it becomes available
 * https://ai.intel.com/lowering-numerical-precision-increase-deep-learning-performance/
 */

/*
 * Copyright (C) 2018 Alexander Nasonov.
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

.text; .align 16; .globl u32toa; .type u32toa,@function; u32toa:;
	cmp    esi,99
	ja     1f

	/* Process 1 or 2 digits. */

	mov    edx,esi
	imul   rdx,rdx,103
	shr    rdx,10
	lea    eax,[rdx+0x30]
	mov    BYTE PTR [rdi],al
	lea    edx,[rdx+rdx*4]
	add    edx,edx
	cmp    esi,10
	sbb    rdi,-2
	sub    esi,edx
	add    esi,0x30
	mov    BYTE PTR [rdi-1],sil
	mov    rax,rdi
	ret
1:
	vmovdqa xmm2,XMMWORD PTR [u32toa_first_madd]
	vmovdqa xmm3,XMMWORD PTR [u32toa_second_madd]
	mov     r9d,0x0d090501 /* shuffle 4 digits to low bytes */

	cmp    esi,9999
	ja     2f

	/* Process 3-4 digits. */

	vmovd    xmm0,esi
	vpshufb  xmm0,xmm0,XMMWORD PTR [u32toa_populate_u16]
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,XMMWORD PTR [u32toa_mask]
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,XMMWORD PTR [u32toa_ascii_zero]

	/* Advance the out pointer and prepare for a shuffle. */
	mov    ecx,0x0d090905 /* shuffle 3 digits 0bcd to bccd */
	mov    rax,rdi
	cmp    esi,1000
	cmovl  r9d,ecx
	sbb    rax,-4
	vmovd  xmm4,r9d

	/*
	 * Shuffle digits to low bytes of xmm0 and write
	 * 2 words (possibly overlapping) to the buffer.
	 */
	vpshufb xmm0,xmm0,xmm4
	vmovd   edx,xmm0
	mov     WORD PTR [rdi],dx
	shr     edx,16
	mov     WORD PTR [rax-2],dx
	ret
2:
	mov    eax,esi
	mov    ecx,3518437209
	mul    ecx
	shr    edx,13 /* n / 10000 */
	imul   r8d,edx,10000
	vmovd  xmm4,r9d

	cmp    esi,999999
	ja     3f

	/* Process 5-6 digits. */

	sub      esi,r8d /* n % 10000 */
	vmovd    xmm0,esi
	vpshufb  xmm0,xmm0,XMMWORD PTR [u32toa_populate_u16]        # 6012a0 <u32toa_populate_u16>
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,XMMWORD PTR [u32toa_mask]        # 6012b0 <u32toa_mask>
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,XMMWORD PTR [u32toa_ascii_zero]        # 6012c0 <u32toa_ascii_zero>
	vpshufb  xmm0,xmm0,xmm4

	imul   rcx,rdx,103
	shr    rcx,10
	lea    esi,[rcx+0x30]
	mov    BYTE PTR [rdi],sil
	lea    ecx,[rcx+rcx*4]
	add    ecx,ecx
	cmp    edx,10
	lea    rax,[rdi+4]
	sbb    rax,-2
	sub    edx,ecx
	add    edx,0x30
	mov    BYTE PTR [rax-5],dl
	vmovd  DWORD PTR [rax-4],xmm0
	ret
3:
	/* Preload more constants before jumping. */
	vmovdqa xmm5,XMMWORD PTR [u32toa_populate_u16]
	vmovdqa xmm6,XMMWORD PTR [u32toa_mask]
	vmovdqa xmm7,XMMWORD PTR [u32toa_ascii_zero]

	cmp    esi,99999999
	ja     4f

	/* Process 7-8 digits. */

	sub    esi,r8d /* n % 10000 */

	vmovd    xmm0,esi
	vpshufb  xmm0,xmm0,xmm5
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,xmm6
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,xmm7
	vpshufb  xmm4,xmm0,xmm4

	/* Advance the out pointer and prepare for a shuffle. */
	mov    ecx,0x0d0905 /* shuffle 3 digits to low bytes */
	mov    rax,rdi
	cmp    edx,1000
	cmovl  r9d,ecx
	sbb    rax,-8

	vmovd    xmm0,edx
	vpshufb  xmm0,xmm0,xmm5
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,xmm6
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,xmm7
	vmovd    xmm5,r9d
	vpshufb  xmm0,xmm0,xmm5

	vmovd  DWORD PTR [rdi],xmm0
	vmovd  DWORD PTR [rax-4],xmm4

	ret
4:
	/* Process 9-10 digits. */

	sub    esi,r8d /* n % 10000 */
	vmovd  xmm0,esi

	mov    eax,edx
	mov    esi,edx
	mul    ecx
	shr    edx,13 /* n / 10000 / 10000 */
	imul   r8d,edx,10000
	sub    esi,r8d /* n / 10000 % 10000 */

	cmp    edx,10
	lea    rax,[rdi+10]
	sbb    rax,0

	vpshufb  xmm0,xmm0,xmm5
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,xmm6
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,xmm7
	vpshufb  xmm0,xmm0,xmm4
	vmovd    DWORD PTR [rax-4],xmm0

	imul   r8,rdx,103
	shr    r8d,10
	lea    ecx,[r8d+0x30]
	mov    WORD PTR [rdi],cx
	lea    ecx,[r8d+r8d*4]
	add    ecx,ecx
	sub    edx,ecx
	add    edx,0x30
	mov    BYTE PTR [rax-9],dl

	vmovd    xmm0,esi
	vpshufb  xmm0,xmm0,xmm5
	vpmaddwd xmm0,xmm0,xmm2
	vpand    xmm0,xmm0,xmm6
	vpslldq  xmm1,xmm0,2
	vpor     xmm0,xmm0,xmm1
	vpmaddwd xmm0,xmm0,xmm3
	vpor     xmm0,xmm0,xmm7
	vpshufb  xmm0,xmm0,xmm4
	vmovd    DWORD PTR [rax-8],xmm0

	ret
.size u32toa, . - u32toa

.data

.align 16
u32toa_first_madd: .short 8389, 0, 10486, 0, 26215, 0, -32768, -32768

.align 16
u32toa_populate_u16: .byte 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1

.align 16
u32toa_mask: .short 0, 0xff80, 0, 0xfff0, 0, 0xfffc, 0, 0xffff

.align 16
u32toa_ascii_zero: .int 0x3000, 0x3000, 0x3000, 0x3000

.align 16
u32toa_second_madd: .short 0, 2, -20, 16, -160, 64, -640, -256
