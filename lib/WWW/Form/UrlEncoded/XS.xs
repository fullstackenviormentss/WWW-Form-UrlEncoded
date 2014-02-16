#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include "ppport.h"

static char escapes[256] = 
/*  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f */
{
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};
static char xdigit[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

static
void
split_kv(char *start, char *end, char **key, int *key_len, char **value, int *value_len) {
    char *cur = start;
    int found_eq = 0;
    if ( *cur == ' ' ) {
        cur++;
        start++;
    }
    while (cur != end) {
        if (*cur == '=') {
            found_eq = 1;
            *key = start;
            *key_len = cur - start;
            cur++;
            break;
        }
        cur++;
    }
    if (found_eq) {
        *value = cur;
        *value_len = end - cur;
    } else {
        *key = start;
        *key_len = end - start;
        *value_len = 0;
    }
}

static SV *
url_decode(pTHX_ const char *src, int src_len) {
    int dlen = 0, i = 0;
    char *d;
    char s2, s3;
    SV * dst;

    dst = newSV(0);
    (void)SvUPGRADE(dst, SVt_PV);
    d = SvGROW(dst, src_len * 3 + 1);

    for (i = 0; i < src_len; i++ ) {
        if (src[i] == '+'){
            d[dlen++] = ' ';
        }
        else if ( src[i] == '%' && isxdigit(src[i+1]) && isxdigit(src[i+2]) ) {
            s2 = src[i+1];
            s3 = src[i+2];
            s2 -= s2 <= '9' ? '0'
                : s2 <= 'F' ? 'A' - 10
                            : 'a' - 10;
            s3 -= s3 <= '9' ? '0'
                : s3 <= 'F' ? 'A' - 10
                            : 'a' - 10;
            d[dlen++] = s2 * 16 + s3;
            i += 2;
        }
        else {
            d[dlen++] = src[i];
        }
    }

    SvCUR_set(dst, dlen);
    SvPOK_only(dst);
    return dst;
}

static
void
url_encode_key(const char *src, int src_len, char *d, int *key_len) {
    int i, dlen = 0;
    U8 s;
    for (i=0; i < src_len; i++ ) {
        s = src[i];
        if ( s == ' ' ) {
            d[dlen++] = '+';
        }
        else if ( escapes[s] ) {
            d[dlen++] = '%';
            d[dlen++] = xdigit[s >> 4];
            d[dlen++] = xdigit[s % 16];
        }
        else {
            d[dlen++] = s;
        }
    }
    d[dlen++] = '=';
    *key_len = dlen;
}

static
void
url_encode_val(char * dst, int *dst_len, const char * src, int src_len ) {
    int i;
    int dlen = *dst_len;
    U8 s;

    for ( i=0; i<src_len; i++) {
        s = src[i];
        if ( s == ' ' ) {
            dst[dlen++] = '+';
        }
        else if ( escapes[s] ) {
            dst[dlen++] = '%';
            dst[dlen++] = xdigit[s >> 4];
            dst[dlen++] = xdigit[s % 16];
        }
        else {
            dst[dlen++] = s;
        }
    }
    dst[dlen++] = '&';
    *dst_len = dlen;
}

static
void
memcat( char * dst, int *dst_len, const char * src, int src_len ) {
    int i;
    int dlen = *dst_len;
    for ( i=0; i<src_len; i++) {
        dst[dlen++] = src[i];
    }
    *dst_len = dlen;
}

MODULE = WWW::Form::UrlEncoded::XS    PACKAGE = WWW::Form::UrlEncoded::XS

PROTOTYPES: DISABLE

void
parse_urlencoded(qs)
    char *qs
  PREINIT:
    char *cur = qs;
    char *prev = qs;
    char *key, *value;
    int key_len, value_len;
  PPCODE:
    while (*cur != '\0') {
        if (*cur == '&' || *cur == ';') {
            split_kv(prev, cur, &key, &key_len, &value, &value_len);
            PUSHs(sv_2mortal(url_decode(aTHX_ key, key_len)));
            PUSHs(sv_2mortal(url_decode(aTHX_ value, value_len)));
            cur++;
            prev = cur;
        } else {
            cur++;
        }
    }

    if (prev != cur) {
        split_kv(prev, cur, &key, &key_len, &value, &value_len);
        PUSHs(sv_2mortal(url_decode(aTHX_ key, key_len)));
        PUSHs(sv_2mortal(url_decode(aTHX_ value, value_len)));
    }

    --cur;
    if ( *cur == '&' || *cur == ';' ) {
        PUSHs(sv_2mortal(newSVpv("",0)));
        PUSHs(sv_2mortal(newSVpv("",0)));
    }


SV *
build_urlencoded(...)
  PREINIT:
    int i, j, dlen = 0, key_len, val_len;
    SV *dst, *av_val;
    AV *a_val;
    char *d, *key_src, *val_src, *key;
    STRLEN key_src_len, val_src_len;
  CODE:
    dst = newSV(0);
    (void)SvUPGRADE(dst, SVt_PV);
    d = SvGROW(dst, 128);
    for( i=0; i < items; i++ ) {
        if ( !SvOK(ST(i)) ) {
            Newx(key,1,char);
            key_len = 1;
            key[0] = '=';
        }
        else {
            key_src = (char *)SvPV(ST(i),key_src_len);
            Newx(key,key_src_len * 3 + 1, char);
            url_encode_key(key_src, key_src_len, key, &key_len);
        }

        /* value */
        i++;

        if ( i == items ) {
            /* key is last  */
            key[key_len++] = '&';
            d = SvGROW(dst, dlen + key_len);
            memcat(d, &dlen, key, key_len);
        }
        else {
            if ( !SvOK(ST(i)) ) {
                /* key but last or value is undef */
                key[key_len++] = '&';
                d = SvGROW(dst, dlen + key_len);
                memcat(d, &dlen, key, key_len);
            }
            else if ( SvROK(ST(i)) && SvTYPE(SvRV(ST(i))) == SVt_PVAV ) {
                /* array ref */
                a_val = (AV *)SvRV(ST(i));
                for (j=0; j<=av_len(a_val); j++) {
                    av_val = *av_fetch(a_val,j,0);
                    if ( !SvOK(av_val) ) {
                        d = SvGROW(dst, dlen + key_len);
                        memcat(d, &dlen, key, key_len);
                    }
                    else {
                        val_src = (char *)SvPV(av_val,val_src_len);
                        d = SvGROW(dst, dlen + key_len + (val_src_len*3) + 1);
                        memcat(d, &dlen, key, key_len);
                        url_encode_val(d, &dlen, val_src, val_src_len);
                    }
                }
            }
            else {
                /* sv */
                val_src = (char *)SvPV(ST(i),val_src_len);
                d = SvGROW(dst, dlen + key_len + (val_src_len*3) + 1);
                memcat(d, &dlen, key, key_len);
                url_encode_val(d, &dlen, val_src, val_src_len);
            }
        }
        Safefree(key);
    }

    if ( dlen > 0 && d[dlen-1] == '&' ) {
      dlen = dlen - 1;
    }
    SvCUR_set(dst, dlen);
    SvPOK_only(dst);
    RETVAL = dst;
  OUTPUT:
    RETVAL

