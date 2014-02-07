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

__END__

=encoding utf-8

=head1 NAME

WWW::Form::UrlEncoded::PP - pure-perl parser for application/x-www-form-urlencoded

=head1 SYNOPSIS

    use WWW::Form::UrlEncoded::PP qw/parse_urlencoded/;

    my $query_string = "foo=bar&baz=param";
    my @params = parse_urlencoded($query_string);
    # ('foo','bar','baz','param')

=head1 DESCRIPTION

WWW::Form::UrlEncoded::PP provides pure-perl application/x-www-form-urlencoded parser.
see L<WWW::Form::UrlEncoded>'s document.

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

