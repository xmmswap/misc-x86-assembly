#include "hhmmss.h"

#include <err.h>
#include <inttypes.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <emmintrin.h>
#include <smmintrin.h>

#define REQUIRE(x) if (!(x)) { \
	errx(EXIT_FAILURE, "%s:%u (in %s): %s\nAborted",  \
	    __FILE__, __LINE__, __func__, #x); }


#if 0
int
hhmmss(__m128i d)
{
	// Colons are at positions 2 and 5, digits are at positions 0-1, 3-4 and 6-7.
	__m128i xor = _mm_set_epi8(0, 0, 0, 0, 0, 0, 0, 0, '0', '0', ':', '0', '0', ':', '0', '0');
	__m128i shuf = _mm_set_epi8(2, 7, 5, 6, 2, 4, 5, 3, 2, 1, 5, 0, 2, 1, 5, 0);
	__m128i sat = _mm_set_epi16(65525, 65525, 65525, 65525, 65525, 65525, 65525, 65525);
	__m128i mul = _mm_set_epi16(1, 10, 60, 600, 1800, 18000, 1800, 18000);
	__m128i max = _mm_set_epi32(59, 3540, 41400, 41400); // 23:59:59
	__m128i cmp;

	d = _mm_xor_si128(d, xor);
	d = _mm_shuffle_epi8(d, shuf);

	cmp = _mm_adds_epu16(d, sat);

	d = _mm_madd_epi16(d, mul);

	cmp = _mm_adds_epu16(cmp, _mm_cmpgt_epi32(d, max));
	cmp = _mm_cmpeq_epi16(cmp, _mm_set1_epi8(255));

	if (__predict_false(!_mm_test_all_zeros(cmp, cmp)))
		return UINT32_MAX;

	d = _mm_add_epi32(d, _mm_shuffle_epi32(d, _MM_SHUFFLE(1, 0, 3, 2)));
	d = _mm_add_epi32(d, _mm_shuffle_epi32(d, _MM_SHUFFLE(2, 3, 0, 1)));

	return _mm_cvtsi128_si32(d);
}
#endif

static int
hhmmss_from_str(const char *str)
{
	uint64_t n;

	memcpy(&n, str, sizeof(n));
	return hhmmss(_mm_cvtsi64_si128(n));
}


int main()
{
	unsigned h, m, s;
	char buf[8];

	REQUIRE(hhmmss_from_str("23:60:59") == -1);
	REQUIRE(hhmmss_from_str("23:59:60") == -1);
	REQUIRE(hhmmss_from_str("24:59:59") == -1);
	REQUIRE(hhmmss_from_str("00:00=00") == -1);
	REQUIRE(hhmmss_from_str("00^00:00") == -1);
	REQUIRE(hhmmss_from_str("00000000") == -1);

	buf[2] = buf[5] = ':';

	for (h = 0; h < 24; h++) {
		buf[0] = '0' + h / 10;
		buf[1] = '0' + h % 10;

		for (m = 0; m < 60; m++) {
			buf[3] = '0' + m / 10;
			buf[4] = '0' + m % 10;

			for (s = 0; s < 60; s++) {
				buf[6] = '0' + s / 10;
				buf[7] = '0' + s % 10;

				int r = hhmmss_from_str(buf);
				REQUIRE(r == s + 60 * m + 3600 * h);
			}
		}
	}

	return EXIT_SUCCESS;
}
