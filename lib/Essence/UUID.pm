#! /usr/bin/perl

package Essence::UUID;

use Essence::Strict;

use MIME::Base64;
use MIME::Base64::URLSafe;

use Exporter qw( import );
our @EXPORT = qw( uuid_bin uuid_hex uuid_base64 uuid_url64 );

my $mod_name = __PACKAGE__;

sub uuid_bin
{
  state $urandom_buffer_pid;
  state $urandom_buffer;
  state $urandom_fh;

  ($urandom_buffer_pid, $urandom_buffer) = ()
    if (defined($urandom_buffer_pid) && ($urandom_buffer_pid != $$));

  if (!defined($urandom_buffer) || (length($urandom_buffer) < 16))
  {
    open($urandom_fh, '<', '/dev/urandom') or
      die "$mod_name: open('/dev/urandom', r): $!\n"
      unless $urandom_fh;
    my $len = sysread($urandom_fh, $urandom_buffer, 4096) or
      die "$mod_name: read('/dev/urandom'): $!\n";
    die "$mod_name: read('/dev/urandom'): Short read.\n"
      unless ($len > 16);
    $urandom_buffer_pid //= $$;
  }

  return substr($urandom_buffer, -16, 16, '');
}

sub uuid_hex { return unpack('H32', uuid_bin()) }
sub uuid_base64 { return encode_base64(uuid_bin(), '') }
sub uuid_url64 { return urlsafe_b64encode(uuid_bin()) }

1
