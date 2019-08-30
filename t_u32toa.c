//#define BENCHMARK

#include "u32toa.h"

#include <err.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifndef BENCHMARK
#define REQUIRE(x) if (!(x)) { \
	errx(EXIT_FAILURE, "%s:%u (in %s): %s\nAborted",  \
	    __FILE__, __LINE__, __func__, #x); }
#endif

/*
 * Each call increments a number stored in digits by 1:
 * "0", "1", ... "9" (len is 1),
 * "10", "11", ... "99" (len is 2)
 * "100", ...
 *
 * Before the first call the arguments must be initialised like this:
 *
 *	len = 1;
 *	strncpy(digists, "0", 11);
 */
static void
increment(char digits[static 11], size_t *len)
{
	size_t l;

	for (l = *len; l > 0; l--) {
		if (digits[l-1] == '9')
			continue;

		digits[l-1]++;

		for (; l < *len; l++)
			digits[l] = '0';
		return;
	}

	digits[0] = '1';

	for (l = *len; l > 0; l--)
		digits[l] = '0';

	*len += 1;
}

int main()
{
	size_t i;
	size_t len = 1;
	char digits[11];
	const char *e;
#ifndef BENCHMARK
	char expected[11];
#endif

	strncpy(digits, "", sizeof(digits));

	e = u32toa(digits, 0);

#ifndef BENCHMARK
	strncpy(expected, "0", sizeof(expected));

	REQUIRE(e == &digits[1]);
	REQUIRE(memcmp(digits, expected, sizeof(expected)) == 0);
#endif

	for (i = 0; i != UINT32_MAX; i++) {
		uint32_t n = i + 1;

		e = u32toa(digits, n);

#ifndef BENCHMARK
		increment(expected, &len);

		REQUIRE(e == &digits[len]);
		REQUIRE(memcmp(digits, expected, sizeof(expected)) == 0);
#endif
	}

	return EXIT_SUCCESS;
}
