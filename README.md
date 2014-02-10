[![Build Status](https://travis-ci.org/kazeburo/WWW-Form-UrlEncoded.png?branch=master)](https://travis-ci.org/kazeburo/WWW-Form-UrlEncoded)
# NAME

WWW::Form::UrlEncoded - parser for application/x-www-form-urlencoded

# SYNOPSIS

    use WWW::Form::UrlEncoded qw/parse_urlencoded/;

    my $query_string = "foo=bar&baz=param";
    my @params = parse_urlencoded($query_string);
    # ('foo','bar','baz','param')

# DESCRIPTION

WWW::Form::UrlEncoded provides application/x-www-form-urlencoded parser.
This module aims to have compatibility with other CPAN modules like 
HTTP::Body's urlencoded parser. And aims be fast by XS implementation.

## Parser rules

WWW::Form::UrlEncoded parsed string in this rule.

1. Split application/x-www-form-urlencoded payload by `&` (U+0026) or `;` (U+003B)
2. Ready empty array to store `name` and `value`
3. For each divided string, apply next steps.
    1. If first character of string is `' '` (U+0020 SPACE), remove it.
    2. If string has `=`, let __name__ be substring from start to first `=`, but excluding first `=`, and remains to be __value__. If there is no strings after first `=`, __value__ to be empty string `""`. If first `=` is first character of the string, let __key__ be empty string `""`. If string does not have any `=`, all of the string to be __key__ and __value__ to be empty string `""`.
    3. replace all `+` (U+002B) with `' '` (U+0020 SPACE).
    4. unescape __name__ and __value__. push them to the array.
4. return the array.

## Test data

    'a=b&c=d'     => ["a","b","c","d"]
    'a=b;c=d'     => ["a","b","c","d"]
    'a=1&b=2;c=3' => ["a","1","b","2","c","3"]
    'a==b&c==d'   => ["a","=b","c","=d"]
    'a=b& c=d'    => ["a","b","c","d"]
    'a=b; c=d'    => ["a","b","c","d"]
    'a=b; c =d'   => ["a","b","c ","d"]
    'a=b;c= d '   => ["a","b","c"," d "]
    'a=b&+c=d'    => ["a","b"," c","d"]
    'a=b&+c+=d'   => ["a","b"," c ","d"]
    'a=b&c=+d+'   => ["a","b","c"," d "]
    'a=b&%20c=d'  => ["a","b"," c","d"]
    'a=b&%20c%20=d' => ["a","b"," c ","d"]
    'a=b&c=%20d%20' => ["a","b","c"," d "]
    'a&c=d'       => ["a","","c","d"]
    'a=b&=d'      => ["a","b","","d"]
    'a=b&='       => ["a","b","",""]
    '&'           => ["","","",""]
    '='           => ["",""]
    ''            => []

# FUNCTION

- @param = parse\_urlencoded($str:String)

    parse `$str` and return Array that contains key-value pairs.

# ENVIRONMENT VALUE

- WWW\_FORM\_URLENCODED\_PP

    If true, WWW::Form::UrlEncoded force to load WWW::Form::UrlEncoded::PP.

# SEE ALSO

CPAN already has some application/x-www-form-urlencoded parser modules like these.

- [URL::Encode](http://search.cpan.org/perldoc?URL::Encode)
- [URL::Encode::XS](http://search.cpan.org/perldoc?URL::Encode::XS)
- [Text::QueryString](http://search.cpan.org/perldoc?Text::QueryString)

They does not fully compatible with WWW::Form::UrlEncoded. Handling of empty key-value
and supporting separator characters are different.

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
