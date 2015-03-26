#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw(
    normalize_str camelcase
    quote_html unquote_html remove_html
    pick picks );

is( normalize_str(' alma  barac '),
    'alma barac',
    'normalize_str');

is( camelcase('hello_world'),
    'HelloWorld',
    'camelcase');
is( camelcase('_hello_world'),
    '_HelloWorld',
    'camelcase private');

is( quote_html("a&b <c> \"x's\""),
    "a&amp;b &lt;c&gt; &quot;x's&quot;",
    'quote_html');
is( unquote_html("a&amp;b &lt;c&gt; &quot;x's&quot;"),
    "a&b <c> \"x's\"",
    'unquote_html');
like(remove_html('<h1 class="alma">barack</h1>'),
    qr/^\s*barack\s*\z/,
    'remove_html');

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
