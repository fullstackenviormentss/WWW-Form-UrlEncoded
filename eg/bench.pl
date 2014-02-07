#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use WWW::Form::UrlEncoded;
use WWW::Form::UrlEncoded::PP;
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
    '%E6%97%A5%E6%9C%AC%E8%AA%9E=%E3%81%AB%E3%81%BB%E3%82%93%E3%81%94&%E3%81%BB%E3%81%92%E3%81%BB%E3%81%92=%E3%81%B5%E3%81%8C%E3%81%B5%E3%81%8C',
);


my $xs = Text::QueryString->new;

cmpthese(-1, {
    text_qs => sub {
        foreach my $qs (@query_string) {
            my @q = $xs->parse($qs);
        }
    },
    wwwform => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::parse_urlencoded($qs);
        }
    },
    wwwform_pp => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::PP::parse_urlencoded($qs);
        }
    },
    urlencode => sub {
        foreach my $qs (@query_string) {
            my @q = URL::Encode::url_params_flat($qs);
        }
    },
});


__END__
              Rate wwwform_pp    text_qs    wwwform  urlencode
wwwform_pp 11933/s         --       -78%       -87%       -88%
text_qs    54098/s       353%         --       -42%       -44%
wwwform    93699/s       685%        73%         --        -3%
urlencode  96376/s       708%        78%         3%         --


