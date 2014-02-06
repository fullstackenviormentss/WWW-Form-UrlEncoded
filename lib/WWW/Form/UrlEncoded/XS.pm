package WWW::Form::UrlEncoded::XS;

use strict;
use warnings;
use base qw/Exporter/;

our $VERSION = 0.01;
our @EXPORT_OK = qw/parse_urlencoded/;

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;

