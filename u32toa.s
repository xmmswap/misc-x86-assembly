/* This is AUTO-GENERATED file, don't modify. */

/*
 * Copyright (C) 2018 Alexander Nasonov.
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

# 1 "u32toa.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "u32toa.S"
# 66 "u32toa.S"
# 1 "/usr/include/amd64/asm.h" 1 3 4
# 67 "u32toa.S" 2


.text; .align 16; .globl u32toa; .type u32toa,@function; u32toa:;
 cmp $99, %esi
 ja 1f



 mov %esi, %edx
 imul $103, %rdx, %rdx
 shr $10, %rdx
 lea 0x30(%rdx), %eax
 mov %al, (%rdi)
 lea (%rdx,%rdx,4), %edx
 add %edx, %edx
 cmp $10, %esi
 sbb $-2, %rdi
 sub %edx, %esi
 add $0x30, %esi
 mov %sil, -1(%rdi)
 mov %rdi, %rax
 ret
1:
 vmovdqa u32toa_first_madd(%rip), %xmm2
 vmovdqa u32toa_second_madd(%rip), %xmm3
 mov $0x0d090501, %r9d

 cmp $9999, %esi
 ja 2f



 vmovd %esi, %xmm0
 vpshufb u32toa_populate_u16(%rip), %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand u32toa_mask(%rip), %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor u32toa_ascii_zero(%rip), %xmm0, %xmm0


 mov $0x0d090905, %ecx
 mov %rdi, %rax
 cmp $1000, %esi
 cmovl %ecx, %r9d
 sbb $-4, %rax
 vmovd %r9d, %xmm4





 vpshufb %xmm4, %xmm0, %xmm0
 vmovd %xmm0, %edx
 mov %dx, (%rdi)
 shr $16, %edx
 mov %dx, -2(%rax)
 ret
2:
 mov %esi, %eax
 mov $3518437209, %ecx
 mul %ecx
 shr $13, %edx
 imul $10000, %edx, %r8d
 vmovd %r9d, %xmm4

 cmp $999999, %esi
 ja 3f



 sub %r8d, %esi
 vmovd %esi, %xmm0
 vpshufb u32toa_populate_u16(%rip), %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand u32toa_mask(%rip), %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor u32toa_ascii_zero(%rip), %xmm0, %xmm0
 vpshufb %xmm4, %xmm0, %xmm0

 imul $103, %rdx, %rcx
 shr $10, %rcx
 lea 0x30(%rcx), %esi
 mov %sil, (%rdi)
 lea (%rcx,%rcx,4), %ecx
 add %ecx, %ecx
 cmp $10, %edx
 lea 4(%rdi), %rax
 sbb $-2, %rax
 sub %ecx, %edx
 add $0x30, %edx
 mov %dl, -5(%rax)
 vmovd %xmm0, -4(%rax)
 ret
3:

 vmovdqa u32toa_populate_u16(%rip), %xmm5
 vmovdqa u32toa_mask(%rip), %xmm6
 vmovdqa u32toa_ascii_zero(%rip), %xmm7

 cmp $99999999, %esi
 ja 4f



 sub %r8d, %esi

 vmovd %esi, %xmm0
 vpshufb %xmm5, %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand %xmm6, %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor %xmm7, %xmm0, %xmm0
 vpshufb %xmm4, %xmm0, %xmm4


 mov $0x0d0905, %ecx
 mov %rdi, %rax
 cmp $1000, %edx
 cmovl %ecx, %r9d
 sbb $-8, %rax

 vmovd %edx, %xmm0
 vpshufb %xmm5, %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand %xmm6, %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor %xmm7, %xmm0, %xmm0
 vmovd %r9d, %xmm5
 vpshufb %xmm5, %xmm0, %xmm0

 vmovd %xmm0, (%rdi)
 vmovd %xmm4, -4(%rax)

 ret
4:


 sub %r8d, %esi
 vmovd %esi, %xmm0

 mov %edx, %eax
 mov %edx, %esi
 mul %ecx
 shr $13, %edx
 imul $10000, %edx, %r8d
 sub %r8d, %esi

 cmp $10, %edx
 lea 10(%rdi), %rax
 sbb $0, %rax

 vpshufb %xmm5, %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand %xmm6, %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor %xmm7, %xmm0, %xmm0
 vpshufb %xmm4, %xmm0, %xmm0
 vmovd %xmm0, -4(%rax)

 imul $103, %rdx, %r8
 shr $10, %r8d
 lea 0x30(%r8d), %ecx
 mov %cx, (%rdi)
 lea (%r8d,%r8d,4), %ecx
 add %ecx, %ecx
 sub %ecx, %edx
 add $0x30, %edx
 mov %dl, -9(%rax)

 vmovd %esi, %xmm0
 vpshufb %xmm5, %xmm0, %xmm0
 vpmaddwd %xmm2, %xmm0, %xmm0
 vpand %xmm6, %xmm0, %xmm0
 vpslldq $2, %xmm0, %xmm1
 vpor %xmm1, %xmm0, %xmm0
 vpmaddwd %xmm3, %xmm0, %xmm0
 vpor %xmm7, %xmm0, %xmm0
 vpshufb %xmm4, %xmm0, %xmm0
 vmovd %xmm0, -8(%rax)

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
