#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw( pick );

is_deeply(
    pick({ 'a' => 1, 'b' => 2 }, qw( a c )),
    { 'a' => 1, 'c' => undef },
    'pick');

done_testing();
