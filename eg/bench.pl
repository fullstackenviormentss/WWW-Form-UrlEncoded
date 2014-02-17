#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use WWW::Form::UrlEncoded;
use WWW::Form::UrlEncoded::PP;
use URL::Encode::XS;
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

cmpthese(timethese(-1, {
    text_qs => sub {
        foreach my $qs (@query_string) {
            my @q = $xs->parse($qs);
        }
    },
    wwwform_xs => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::XS::parse_urlencoded($qs);
        }
    },
    wwwform_pp => sub {
        foreach my $qs (@query_string) {
            my @q = WWW::Form::UrlEncoded::PP::parse_urlencoded($qs);
        }
    },
    urlencode_xs => sub {
        foreach my $qs (@query_string) {
            my @q = @{URL::Encode::XS::url_params_flat($qs)};
        }
    },
}));


__END__
Benchmark: running text_qs, urlencode_xs, wwwform_pp, wwwform_xs for at least 1 CPU seconds...
   text_qs:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 53096.30/s (n=57344)
urlencode_xs:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 66369.44/s (n=71679)
wwwform_pp:  1 wallclock secs ( 1.06 usr +  0.01 sys =  1.07 CPU) @ 11821.50/s (n=12649)
wwwform_xs:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 91021.90/s (n=95573)
                Rate   wwwform_pp      text_qs urlencode_xs   wwwform_xs
wwwform_pp   11821/s           --         -78%         -82%         -87%
text_qs      53096/s         349%           --         -20%         -42%
urlencode_xs 66369/s         461%          25%           --         -27%
wwwform_xs   91022/s         670%          71%          37%           --


