#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw/:all/;
use URI;
use URI::Escape;
use URL::Encode::XS qw/url_encode/;
use WWW::Form::UrlEncoded::XS qw/build_urlencoded/;

my $base = q!http://api.example.com!;
my $path = q!/path/to/endpoint!;
my %param = (
    token => 'b a r',
    message => 'foo bar baz hoge hoge hoge hoge hogehoge',
    hoge => '日本語ですよー',
    arrayref => [qw/1 2 5/]
);

my @qs = (
    s_id => 1,
    type => 'foo',
    %param
);
warn build_urlencoded(@qs);

cmpthese(timethese(-2, {
    'uri' => sub {
        my $uri = URI->new($base . $path);
        $uri->query_form(
            s_id => 1,
            type => 'foo',
            %param
        );
        $uri->as_string;
    },
    'concat_uri' => sub {
        my @qs = (
            s_id => 1,
            type => 'foo',
            %param
        );
        my $uri = $base . $path . '?';
        while ( @qs ) {
            my $k = shift @qs;
            my $v = shift @qs;
            if ( ref $v && ref $v eq 'ARRAY') {
                $uri .= uri_escape($k) . '='. uri_escape($_) . '&' for @$v;
            }
            else {
                $uri .= uri_escape($k) . '='. uri_escape($v) . '&'
            }
        }
        substr($uri,-1,1,"");
        $uri;

    },
    'concat_xs' => sub {
        my @qs = (
            s_id => 1,
            type => 'foo',
            %param
        );
        my $uri = $base . $path . '?';
        while ( @qs ) {
            my $k = shift @qs;
            my $v = shift @qs;
            if ( ref $v && ref $v eq 'ARRAY') {
                $uri .= url_encode($k) . '='. url_encode($_) . '&' for @$v;
            }
            else {
                $uri .= url_encode($k) . '='. url_encode($v) . '&'
            }
        }
        substr($uri,-1,1,"");
        $uri;
    },
    'build_urlencoded' => sub {
        my $uri = $base . $path . '?' . build_urlencoded(
            s_id => 1,
            type => 'foo',
            %param
        );
        $uri;
    },
}));

__END__
Benchmark: running concat, concat_xs, uri for at least 2 CPU seconds...
    concat:  2 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 81818.63/s (n=166910)
 concat_xs:  2 wallclock secs ( 2.17 usr +  0.00 sys =  2.17 CPU) @ 277470.51/s (n=602111)
       uri:  2 wallclock secs ( 2.20 usr +  0.00 sys =  2.20 CPU) @ 25653.18/s (n=56437)
              Rate       uri    concat concat_xs
uri        25653/s        --      -69%      -91%
concat     81819/s      219%        --      -71%
concat_xs 277471/s      982%      239%        --

