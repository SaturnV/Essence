#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Utils qw(
    xeq xne
    normalize_str camelcase
    quote_html unquote_html remove_html
    pick picks );

{
  my $q = {};
  my @tests = (
      [ undef, undef, 1, 'undef == undef' ],
      [ undef, 'a', 0, 'undef != scalar' ],
      [ 'a', undef, 0, 'scalar != undef' ],
      [ 'a', 'a', 1, 'scalar == scalar' ],
      [ 'a', 'b', 0, 'scalar != scalar' ],
      [ $q, undef, 0, 'ref != undef' ],
      [ undef, $q, 0, 'undef != ref' ],
      [ $q, 'a', 0, 'scalar != ref' ],
      [ 'a', $q, 0, 'ref != scalar' ],
      [ $q, "$q", 0, 'ref != str' ],
      [ "$q", $q, 0, 'str != ref' ],
      [ $q, $q, 1, 'ref == ref' ],
      [ $q, {}, 0, 'ref != other ref'],
      [ "$q", "$q", 1, 'str == str']);
  foreach my $t (@tests)
  {
    # ok(xeq($t->[0], $t->[1]) xor $t->[2], "xeq $t->[3]");
    # ok(xne($t->[0], $t->[1]) xor !$t->[2], "xne $t->[3]");

    if ($t->[2])
    {
      ok(xeq($t->[0], $t->[1]), "xeq $t->[3]");
      ok(!xne($t->[0], $t->[1]), "xne $t->[3]");
    }
    else
    {
      ok(!xeq($t->[0], $t->[1]), "xeq $t->[3]");
      ok(xne($t->[0], $t->[1]), "xne $t->[3]");
    }
  }
}

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
