#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw( normalize_str camelcase pick picks );

is( normalize_str(' alma  barac '),
    'alma barac',
    'normalize_str');

is( camelcase('hello_world'),
    'HelloWorld',
    'camelcase');
is( camelcase('_hello_world'),
    '_HelloWorld',
    'camelcase private');

is_deeply(
    { pick({ 'a' => 1, 'b' => 2 }, qw( a c )) },
    { 'a' => 1 },
    'pick list');
is_deeply(
    scalar(pick({ 'a' => 1, 'b' => 2 }, qw( a c ))),
    { 'a' => 1 },
    'pick scalar');
is_deeply(
    picks({ 'a' => 1, 'b' => 2 }, qw( a c )),
    { 'a' => 1 },
    'picks');

done_testing();
