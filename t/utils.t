#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw( pick );

is_deeply(
    scalar(pick({ 'a' => 1, 'b' => 2 }, qw( a c ))),
    { 'a' => 1, 'c' => undef },
    'pick scalar');
is_deeply(
    { pick({ 'a' => 1, 'b' => 2 }, qw( a c )) },
    { 'a' => 1, 'c' => undef },
    'pick list');

done_testing();
