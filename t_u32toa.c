//#define PROGRESS

#include "u32toa.h"

#include <err.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef PROGRESS
#include <stdio.h>
#endif

#define REQUIRE(x) if (!(x)) { \
	errx(EXIT_FAILURE, "%s:%u (in %s): %s\nAborted",  \
	    __FILE__, __LINE__, __func__, #x); }


/*
 * All digits[i] bytes must be initialised to NUL before the first call.
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
	char digits[11] = { };
	char expected[11] = { '0' };
	const char *e;

	e = u32toa(digits, 0);
	REQUIRE(e == &digits[1]);
	REQUIRE(memcmp(digits, expected, sizeof(expected)) == 0);

	for (i = 0; i != UINT32_MAX; i++) {
		uint32_t n = i + 1;
#ifdef PROGRESS
		size_t old_len = len;
#endif

		increment(expected, &len);

#ifdef PROGRESS
		if (old_len != len)
			printf("Testing %s (%zu digits)\n", expected, len);
#endif

		e = u32toa(digits, n);

		REQUIRE(e == &digits[len]);
		REQUIRE(memcmp(digits, expected, sizeof(expected)) == 0);
	}

	return EXIT_SUCCESS;
}
