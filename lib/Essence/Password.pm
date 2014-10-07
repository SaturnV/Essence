#! /usr/bin/perl

package Essence::Password;

use Essence::Strict;

use Encode;
use Crypt::Eksblowfish::Bcrypt qw( en_base64 bcrypt );
use Exporter qw( import );

use Essence::UUID;

our @EXPORT_OK = qw( hash_password check_password );

our $Rounds = 10;

# $pwd_hash = _bcrypt_utf8($salt, $pwd_plain);
sub _bcrypt_utf8 { return bcrypt(Encode::encode('UTF-8', $_[1]), $_[0]) }

sub hash_password
{
  # my ($pwd_plain, $salt) = @_;
  # $salt //= "\$2a\$$Rounds\$" . en_base64(uuid_bin());
  # return _bcrypt_utf8($salt, $pwd_plain);
  return _bcrypt_utf8(
      $_[1] // ("\$2a\$$Rounds\$" . en_base64(uuid_bin())),
      $_[0]);
}

sub check_password
{
  # my ($pwd_hash, $pwd_plain) = @_;
  # return (defined($pwd_hash) && defined($pwd_plain) &&
  #         ($pwd_hash eq _bcrypt_utf8($pwd_hash, $pwd_plain)));
  return (defined($_[0]) && defined($_[1]) && ($_[0] eq _bcrypt_utf8(@_)));
}

1
