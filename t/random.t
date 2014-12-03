#! /usr/bin/perl

use Config;
use Test::More tests => 1651;
use Test::Exception;
use Essence::Strict;

my $rng = 'Essence::Random';
use_ok $rng;

my $rnd;

foreach my $i (0 .. 10)
{
  lives_ok { $rnd = $rng->ByteString($i) };
  ok(length($rnd) == $i, "ByteString length $i");
}
dies_ok { $rnd = $rng->ByteString(-7) };
dies_ok { $rnd = $rng->ByteString(8.2) };
dies_ok { $rnd = $rng->ByteString('alma') };
dies_ok { $rnd = $rng->ByteString({}) };

{
  sub check_interval
  {
    my ($method, $min, $max) = (shift, shift, shift);
    foreach my $n (@_)
    {
      ok(defined($n), "$method defined");
      ok($n >= $min, "$method min");
      ok($n <= $max, "$method max");
    }
  }

  sub check_method
  {
    my ($method, $min, $max) = @_;

    check_interval($method, $min, $max, scalar($rng->$method()));
    check_interval($method, $min, $max, scalar($rng->$method(1)));
    dies_ok { scalar($rng->$method(0)) };
    dies_ok { scalar($rng->$method(2)) };
    dies_ok { scalar($rng->$method(-1)) };
    dies_ok { scalar($rng->$method(3.2)) };
    dies_ok { scalar($rng->$method('alma')) };
    dies_ok { scalar($rng->$method({})) };

    my @r;
    foreach my $length (0 .. 10)
    {
      lives_ok { @r = $rng->$method($length) };
      ok(scalar(@r) == $length, "$method length $length");
      check_interval($method, $min, $max, @r);
    }
    dies_ok { @r = $rng->$method(-1) };
    dies_ok { @r = $rng->$method(3.2) };
    dies_ok { @r = $rng->$method('alma') };
    dies_ok { @r = $rng->$method({}) };
  }

  my @sizes = (8, 16, 32);
  push(@sizes, 64) if ($Config{'ivsize'} >= 8);

  my $i_;
  foreach my $i (@sizes)
  {
    $i_ = $i - 1;
    check_method("S$i", - (2 ** $i_), (2 ** $i_) - 1);
    check_method("U$i", 0, (2 ** $i) - 1);
  }
}

done_testing();
