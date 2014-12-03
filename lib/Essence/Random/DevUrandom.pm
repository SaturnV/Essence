#! /usr/bin/perl

package Essence::Random::DevUrandom;

use Essence::Strict;

use parent 'Essence::Random::Generator';

my $mod_name = __PACKAGE__;

sub _urandom_reader
{
  state ($pid, $buffer, $fh);
  my ($n) = @_;

  # fork() compatibility
  ($pid, $buffer) = () if (defined($pid) && ($pid != $$));

  if (length($buffer //= '') < $n)
  {
    my $len = int(4096 + $n) & ~0xfff;

    open($fh, '<', '/dev/urandom') or
      die "$mod_name: open('/dev/urandom', r): $!\n"
      unless $fh;
    $len = sysread($fh, $buffer, $len, length($buffer)) or
      die "$mod_name: read('/dev/urandom'): $!\n";
    die "$mod_name: read('/dev/urandom'): Short read.\n"
      unless (length($buffer) >= $n);

    $pid //= $$;
  }

  return substr($buffer, -$n, $n, '');
}

sub _GetBytes
{
  # my ($self, $n) = @_;
  # return _urandom_reader($n);
  return _urandom_reader($_[1]);
}

1;
