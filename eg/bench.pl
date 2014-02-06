#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use WWW::Form::UrlEncoded;
use URL::Encode;
use Text::QueryString;

my @query_string = (
    "foo=bar",
    "foo=bar&bar=1",
    "foo=bar;bar=1",
    "foo=bar&foo=baz",
    "foo=bar&foo=baz&bar=baz",
    "foo_only",
    "foo&bar=baz",
    "日本語=にほんご&ほげほげ=1&ふがふが",
);
my $xs = Text::QueryString->new;

cmpthese(-1, {
    qs => sub {
        foreach my $qs (@query_string) {
            my @q = $xs->parse($qs);
        }
    },
    wwwform => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::parse_urlencoded($qs);
        }
    },
    urlecode => sub {
        foreach my $qs (@query_string) {
            my @q = URL::Encode::url_params_flat($qs);
        }
    },
});

