#! /usr/bin/perl

use Test::More;
use Test::Deep;
use Essence::Strict;

use Essence::Hash qw( all_keys common_keys );

my $u = { 'a' => 1, 'b' => 2 };
my $v = { 'a' => 1, 'c' => 3 };

cmp_deeply(
    [all_keys($u, $v)],
    bag(qw( a b c )),
    'all_keys');

cmp_deeply(
    [common_keys($u, $v)],
    bag(qw( a )),
    'common_keys');

done_testing();
