#! /usr/bin/perl

use Test::More tests => 1617;
use Test::Exception;
use Essence::Strict;

use_ok 'Essence::UUID';

my $uuid;

foreach (0 .. 100)
{
  lives_ok { $uuid = uuid_bin() };
  ok(defined($uuid), 'bin defined');
  ok(length($uuid) == 16, 'bin length');
  isnt($uuid, uuid_bin(), 'bin same');

  lives_ok { $uuid = uuid_hex() };
  ok(defined($uuid), 'hex defined');
  ok($uuid =~ m|^[0-9a-f]{32}\z|, 'hex regexp');
  isnt($uuid, uuid_hex(), 'hex same');

  #          1111111111222
  # 1234567890123456789012
  # 05+P+F/6lUu3X1LmYjIUGw==
  lives_ok { $uuid = uuid_base64() };
  ok(defined($uuid), 'base64 defined');
  ok($uuid =~ m|^[0-9A-Za-z+/]{22}==\z|, 'base64 regexp');
  isnt($uuid, uuid_base64(), 'base64 same');

  lives_ok { $uuid = uuid_url64() };
  ok(defined($uuid), 'url64 defined');
  ok($uuid =~ m|^[0-9A-Za-z_-]{22}\z|, 'url64 regexp');
  isnt($uuid, uuid_url64(), 'url64 same');
}

done_testing();
