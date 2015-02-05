#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw( pick normalize_str );

is_deeply(
    scalar(pick({ 'a' => 1, 'b' => 2 }, qw( a c ))),
    { 'a' => 1, 'c' => undef },
    'pick scalar');
is_deeply(
    { pick({ 'a' => 1, 'b' => 2 }, qw( a c )) },
    { 'a' => 1, 'c' => undef },
    'pick list');

is(
    normalize_str(' alma  barac '),
    'alma barac',
    'normalize_str');

done_testing();
