package WWW::Form::UrlEncoded;

use 5.008001;
use strict;
use warnings;

BEGIN {
    our $VERSION = "0.01";
    our @EXPORT_OK = qw/parse_urlencoded/;

    my $use_pp = $ENV{WWW_FORM_URLENCODED_PP};

    if (!$use_pp) {
        eval { 
            require WWW::Form::UrlEncoded::XS;
        };
        $use_pp = !!$@;
    }

    if ($use_pp) {
        require WWW::Form::UrlEncoded::PP;
        WWW::Form::UrlEncoded::PP->import(@EXPORT_OK);
    }
    else {
        WWW::Form::UrlEncoded::XS->import(@EXPORT_OK);
    }

    require Exporter;
    *import = \&Exporter::import;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Form::UrlEncoded - It's new $module

=head1 SYNOPSIS

    use WWW::Form::UrlEncoded;

=head1 DESCRIPTION

WWW::Form::UrlEncoded is ...

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

