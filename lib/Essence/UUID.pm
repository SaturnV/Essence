#! /usr/bin/perl

package Essence::UUID;

use Essence::Strict;

use MIME::Base64;
use MIME::Base64::URLSafe;
use Essence::Random;

use Exporter qw( import );
our @EXPORT = qw( uuid_bin uuid_hex uuid_base64 uuid_url64 );

my $mod_name = __PACKAGE__;

sub uuid_bin { return Essence::Random->ByteString(16) }
sub uuid_hex { return unpack('H32', uuid_bin()) }
sub uuid_base64 { return encode_base64(uuid_bin(), '') }
sub uuid_url64 { return urlsafe_b64encode(uuid_bin()) }

1
