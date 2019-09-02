//#define BENCHMARK

#include "d8x2tou32x2.h"

#include <err.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <emmintrin.h>
#include <smmintrin.h>

#ifndef BENCHMARK
#define REQUIRE(x) if (!(x)) { \
	errx(EXIT_FAILURE, "%s:%u (in %s): %s\nAborted",  \
	    __FILE__, __LINE__, __func__, #x); }
#endif

#ifndef BENCHMARK
static void
increment(char digits[], size_t len)
{
	size_t l;

	for (l = len; l > 0; l--) {
		if (digits[l-1] == '9')
			continue;

		digits[l-1]++;

		for (; l < len; l++)
			digits[l] = '0';
		return;
	}
}
#endif

int main(int argc, char *argv[])
{
	size_t n;
	int lo = 0, hi = 0;
	char digits[16];

	memcpy(digits, "0000000000000000", sizeof(digits));

	for (n = 0; n <= 99999999; n++) {
		__m128i d = _mm_loadu_si128((const __m128i *)digits);

		d = d8x2tou32x2(_mm_xor_si128(d, _mm_set1_epi8('0')));
		hi = _mm_extract_epi32(d, 0);
		lo = _mm_extract_epi32(d, 1);
#ifndef BENCHMARK
		REQUIRE(lo == n);
		REQUIRE(hi == 0);

		increment(digits, sizeof(digits));
#endif
	}

	for (n = 1; n <= 99999999; n++) {
		__m128i d = _mm_loadu_si128((const __m128i *)digits);

		d = d8x2tou32x2(_mm_xor_si128(d, _mm_set1_epi8('0')));
		hi = _mm_extract_epi32(d, 0);
		lo = _mm_extract_epi32(d, 1);
#ifndef BENCHMARK
		REQUIRE(lo == 0);
		REQUIRE(hi == n);

		increment(digits, sizeof(digits) / 2);
#endif
	}

	return lo & hi;
}
