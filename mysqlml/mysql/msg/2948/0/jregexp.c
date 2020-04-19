#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mysql.h>

#include "regex.h"

static const char casetable[] = {
        '\000', '\001', '\002', '\003', '\004', '\005', '\006', '\007',
        '\010', '\011', '\012', '\013', '\014', '\015', '\016', '\017',
        '\020', '\021', '\022', '\023', '\024', '\025', '\026', '\027',
        '\030', '\031', '\032', '\033', '\034', '\035', '\036', '\037',
        /* ' '     '!'     '"'     '#'     '$'     '%'     '&'     ''' */
        '\040', '\041', '\042', '\043', '\044', '\045', '\046', '\047',
        /* '('     ')'     '*'     '+'     ','     '-'     '.'     '/' */
        '\050', '\051', '\052', '\053', '\054', '\055', '\056', '\057',
        /* '0'     '1'     '2'     '3'     '4'     '5'     '6'     '7' */
        '\060', '\061', '\062', '\063', '\064', '\065', '\066', '\067',
        /* '8'     '9'     ':'     ';'     '<'     '='     '>'     '?' */
        '\070', '\071', '\072', '\073', '\074', '\075', '\076', '\077',
        /* '@'     'A'     'B'     'C'     'D'     'E'     'F'     'G' */
        '\100', '\141', '\142', '\143', '\144', '\145', '\146', '\147',
        /* 'H'     'I'     'J'     'K'     'L'     'M'     'N'     'O' */
        '\150', '\151', '\152', '\153', '\154', '\155', '\156', '\157',
        /* 'P'     'Q'     'R'     'S'     'T'     'U'     'V'     'W' */
        '\160', '\161', '\162', '\163', '\164', '\165', '\166', '\167',
        /* 'X'     'Y'     'Z'     '['     '\'     ']'     '^'     '_' */
        '\170', '\171', '\172', '\133', '\134', '\135', '\136', '\137',
        /* '`'     'a'     'b'     'c'     'd'     'e'     'f'     'g' */
        '\140', '\141', '\142', '\143', '\144', '\145', '\146', '\147',
        /* 'h'     'i'     'j'     'k'     'l'     'm'     'n'     'o' */
        '\150', '\151', '\152', '\153', '\154', '\155', '\156', '\157',
        /* 'p'     'q'     'r'     's'     't'     'u'     'v'     'w' */
        '\160', '\161', '\162', '\163', '\164', '\165', '\166', '\167',
        /* 'x'     'y'     'z'     '{'     '|'     '}'     '~' */
        '\170', '\171', '\172', '\173', '\174', '\175', '\176', '\177',
        '\200', '\201', '\202', '\203', '\204', '\205', '\206', '\207',
        '\210', '\211', '\212', '\213', '\214', '\215', '\216', '\217',
        '\220', '\221', '\222', '\223', '\224', '\225', '\226', '\227',
        '\230', '\231', '\232', '\233', '\234', '\235', '\236', '\237',
        '\240', '\241', '\242', '\243', '\244', '\245', '\246', '\247',
        '\250', '\251', '\252', '\253', '\254', '\255', '\256', '\257',
        '\260', '\261', '\262', '\263', '\264', '\265', '\266', '\267',
        '\270', '\271', '\272', '\273', '\274', '\275', '\276', '\277',
        '\300', '\301', '\302', '\303', '\304', '\305', '\306', '\307',
        '\310', '\311', '\312', '\313', '\314', '\315', '\316', '\317',
        '\320', '\321', '\322', '\323', '\324', '\325', '\326', '\327',
        '\330', '\331', '\332', '\333', '\334', '\335', '\336', '\337',
        '\340', '\341', '\342', '\343', '\344', '\345', '\346', '\347',
        '\350', '\351', '\352', '\353', '\354', '\355', '\356', '\357',
        '\360', '\361', '\362', '\363', '\364', '\365', '\366', '\367',
        '\370', '\371', '\372', '\373', '\374', '\375', '\376', '\377',
};

my_bool jregexp_init(UDF_INIT* initid, UDF_ARGS* args, char* message)
{
    struct re_pattern_buffer* re = NULL;
    char* err;

    re_set_casetable(casetable);
    re_mbcinit(MBCTYPE_EUC);

    if (args->arg_count < 2 || args->arg_count > 3) {
	strcpy(message, "JREGEXP() requires two or three arguments");
	return 1;
    }
    if (args->arg_type[0] != STRING_RESULT ||
	args->arg_type[1] != STRING_RESULT ||
	args->arg_count == 3 && args->arg_type[2] != INT_RESULT) {
	strcpy(message, "JREGEXP(): argument type mismatch");
	return 1;
    }
    args->arg_type[0] = STRING_RESULT;
    args->arg_type[1] = STRING_RESULT;
    args->arg_type[2] = INT_RESULT;

    if (args->args[1]) {
	re = malloc(sizeof *re);
	memset(re, 0, sizeof *re);
	re->buffer = malloc(16);
	re->allocated = 16;
	re->fastmap = malloc(256);
	if (args->arg_count == 3)
	    re->options = *((long long*)args->args[2]);
	else
	    re->options = RE_OPTION_IGNORECASE;
	err = re_compile_pattern(args->args[1], args->lengths[1], re);
	if (err) {
	    strncpy(message, err, MYSQL_ERRMSG_SIZE);
	    return 1;
	}
    }

    initid->maybe_null = 0;
    initid->ptr = (char*)re;
    return 0;
}

void jregexp_deinit(UDF_INIT* initid)
{
    if (initid->ptr)
	re_free_pattern((struct re_pattern_buffer*)initid->ptr);
}

long long jregexp(UDF_INIT* initid, UDF_ARGS* args, char* is_null, char* error)
{
    struct re_pattern_buffer* re = (struct re_pattern_buffer*)initid->ptr;
    int ret;
    int compiled = 0;

    if (re == NULL) {
	char* err;

	re = malloc(sizeof *re);
	memset(re, 0, sizeof *re);
	re->buffer = malloc(16);
	re->allocated = 16;
	re->fastmap = malloc(256);
	if (args->arg_count == 3)
	    re->options = *((long long*)args->args[2]);
	else
	    re->options = RE_OPTION_IGNORECASE;
	err = re_compile_pattern(args->args[1], args->lengths[1], re);
	if (err) {
	    *error = 1;
	    return 0;
	}
	compiled = 1;
    }

    ret = re_search(re, args->args[0], args->lengths[0], 0, args->lengths[0], NULL);

    if (compiled)
	re_free_pattern(re);

    if (ret == -2) {
	*error = 1;
	return 0;
    }
    if (ret == -1)
	return 0;
    return 1;
}

unsigned long
scan_oct(start, len, retlen)
const char *start;
int len;
int *retlen;
{
    register const char *s = start;
    register unsigned long retval = 0;

    while (len-- && *s >= '0' && *s <= '7') {
	retval <<= 3;
	retval |= *s++ - '0';
    }
    *retlen = s - start;
    return retval;
}

unsigned long
scan_hex(start, len, retlen)
const char *start;
int len;
int *retlen;
{
    static char hexdigit[] = "0123456789abcdef0123456789ABCDEFx";
    register const char *s = start;
    register unsigned long retval = 0;
    char *tmp;

    while (len-- && *s && (tmp = strchr(hexdigit, *s))) {
	retval <<= 4;
	retval |= (tmp - hexdigit) & 15;
	s++;
    }
    *retlen = s - start;
    return retval;
}
