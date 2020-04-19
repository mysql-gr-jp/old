/* -*- mode: c; coding: euc-jp -*-
 *
 * $Id: mregexp.c,v 1.2 2004/04/07 05:15:17 hirose31 Exp hirose31 $
 *
 */

#include <stdio.h>
#include <string.h>

#include <mysql.h>
#include <oniguruma.h>

#ifdef ENCODING
  #define DEFAULT_ENCODING ENCODING
#else
  #define DEFAULT_ENCODING ONIG_ENCODING_UTF8
#endif

#ifdef DEBUG
  #define DPRINT(s) fprintf(stderr, "%s", s)
#else
  #define DPRINT(s)
#endif

my_bool mregexp_init(UDF_INIT* initid, UDF_ARGS* args, char* message) {
	int r;
	regex_t* reg;
	OnigErrorInfo einfo;
	unsigned char* pattern;
	OnigEncoding enc;
	DPRINT(">>mregexp_init\n");

	if (args->arg_count != 2 && args->arg_count != 3) {
		strcpy(message, "mregexp(): requires two arguments. str,pat[,enc]");
		return 1;
	}
	if (args->arg_type[0] != STRING_RESULT
		|| args->arg_type[1] != STRING_RESULT
		|| ( args->arg_count == 3 && args->arg_type[2] != STRING_RESULT )
		) {
		strcpy(message, "mregexp(): argument type mismatch.");
		return 1;
	}

	pattern = args->args[1];

	enc = DEFAULT_ENCODING;
	if (args->arg_count == 3) { /* fixme ugly... */
		if (strcmp(args->args[2], "ASCII") == 0) {
			enc = ONIG_ENCODING_ASCII;
		} else if (strcmp(args->args[2], "UTF-8") == 0) {
			enc = ONIG_ENCODING_UTF8;
		} else if (strcmp(args->args[2], "EUC-JP") == 0) {
			enc = ONIG_ENCODING_EUC_JP;
		} else if (strcmp(args->args[2], "SJIS") == 0) {
			enc = ONIG_ENCODING_SJIS;
		}
	}

	r = onig_new(&reg, pattern, pattern + strlen(pattern),
				 ONIG_OPTION_DEFAULT, enc, ONIG_SYNTAX_DEFAULT, &einfo);
	if (r != ONIG_NORMAL) {
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r, &einfo);
		strcpy(message, s);
		return 1;
	}

	initid->maybe_null = 0;
	initid->ptr = (char*)reg;
	return 0;
}

void mregexp_deinit(UDF_INIT* initid) {
	DPRINT(">>mregexp_deinit\n");
	if (initid->ptr) {
		onig_free((regex_t*)initid->ptr);
		onig_end();
	}
}

long long mregexp(UDF_INIT* initid, UDF_ARGS* args, char* is_null, char* error) {
	int r;
	regex_t* reg = (regex_t*)initid->ptr;
	OnigRegion *region;
	unsigned char *start, *range, *end;
	unsigned char *str = args->args[0];
	DPRINT(">>mregexp\n");

	region = onig_region_new();

	end   = str + strlen(str);
	start = str;
	range = end;

	r = onig_search(reg, str, end, start, range, region, ONIG_OPTION_NONE);
	onig_region_free(region, 1);

	if (r >= 0) {
		return 1;
	} else if (r == ONIG_MISMATCH) {
		return 0;
	} else { /* error */
		char s[ONIG_MAX_ERROR_MESSAGE_LEN];
		onig_error_code_to_str(s, r);
		fprintf(stderr, "mregexp ERROR: %s\n", s);
		*error = 1;
		return -1;
	}

	return -1;
}

