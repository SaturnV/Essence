#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Merge qw( merge_arrays_keep_order );

is_deeply(
    merge_arrays_keep_order([1,2,3], [4,5,6]),
    [1,2,3,4,5,6],
    'a');
is_deeply(
    merge_arrays_keep_order([1,2,3], [4,5,6,1]),
    [4,5,6,1,2,3],
    'b');

done_testing();
