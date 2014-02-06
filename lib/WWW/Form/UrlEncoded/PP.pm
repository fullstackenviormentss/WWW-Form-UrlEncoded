package WWW::Form::UrlEncoded::PP;

use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT_OK = qw/parse_urlencoded/;

our $DECODE = qr/%([0-9a-fA-F]{2})/;
our %DecodeMap;
for my $num ( 0 .. 255 ) {
    my $h = sprintf "%02X", $num;
    my $chr = chr $num;
    $DecodeMap{ lc $h } = $chr; #%aa
    $DecodeMap{ uc $h } = $chr; #%AA
    $DecodeMap{ ucfirst lc $h } = $chr; #%Aa
    $DecodeMap{ lcfirst uc $h } = $chr; #%aA
}

sub parse_urlencoded {
    return [] unless defined $_[0];
    my @params;
    for my $pair ( split( /[&;] ?/, $_[0], -1 ) ) {
        $pair =~ y/\+/\x20/;
        my ($key, $val) = split /=/, $pair, 2;
        for ($key, $val) {
            if ( ! defined $_ ) { 
                push @params, '';
                next;
            }
            s/$DECODE/$DecodeMap{$1}/gs;
            push @params, $_;
        }
    }

    return @params;
}

1;

