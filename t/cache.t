#! /usr/bin/perl

use Test::More;
use Essence::Strict;

use Essence::Cache;

my $seq = 0;

my $cache = Essence::Cache->new();
isa_ok($cache, 'Essence::Cache');

$cache->Add('a' => 'alma');
$cache->Add('b' => 'barack', 'c' => 'citrom');
$cache->Add({ 'd' => 'datolya', 'e' => 'egres' });

is_deeply([$cache->Get('a')], ['alma'], 'hit a');
is_deeply([$cache->Get('b')], ['barack'], 'hit b');
is_deeply([$cache->Get('c')], ['citrom'], 'hit c');
is_deeply([$cache->Get('d')], ['datolya'], 'hit d');
is_deeply([$cache->Get('e')], ['egres'], 'hit e');

is_deeply([$cache->Get('x')], [], 'miss');
is_deeply([$cache->Get('x', 'x')], ['x'], 'miss-add basic');
is_deeply([$cache->Get('x', 'y')], ['x'], 'hit x miss-add');
is_deeply([$cache->Get('x')], ['x'], 'hit x');
$cache->Remove('x');
is_deeply([$cache->Get('x')], [], 'remove x miss');

# Miss / Add callback
is_deeply(
    [$cache->Get('f', sub { ++$seq ; return 'x' })],
    ['x'],
    'miss-callback fx');
is($seq, 1, 'miss-callback fx seq');

is_deeply(
    [$cache->Get('f', sub { ++$seq ; return 'y' })],
    ['y'],
    'miss-callback fy');
is($seq, 2, 'miss-callback fy seq');

is_deeply([$cache->Get('f')], [], 'miss f');

is_deeply(
    [$cache->Get('f',
         sub
         {
           ++$seq;
           $_[0]->Add($_[1] => 'z');
           return 'z'
         })],
    ['z'],
    'miss-callback fz');
is($seq, 3, 'miss-callback fz seq');

is_deeply(
    [$cache->Get('f',
         sub
         {
           ++$seq;
           $_[0]->Add($_[1] => 'z');
           return 'Z'
         })],
    ['z'],
    'miss-callback fz hit');
is($seq, 3, 'miss-callback fz hit seq');
is_deeply([$cache->Get('f')], ['z'], 'hit f');

$cache->AddWeak('f' => 'Z');
is_deeply([$cache->Get('f')], ['z'], 'AddWeak nop');

$cache->AddWeak('x' => 'x');
is_deeply([$cache->Get('x')], ['x'], 'AddWeak add');

$cache->Remove(qw( f x ));
is_deeply([$cache->Get('f')], [], 'remove multiple f');
is_deeply([$cache->Get('x')], [], 'remove multiple x');

is_deeply(
    [sort $cache->GetLoadedKeys()],
    [qw( a b c d e )],
    'GetLoadedKeys');
is_deeply(
    [sort $cache->GetLoadedObjects()],
    [qw( alma barack citrom datolya egres )],
    'GetLoadedObjects list ctx');
is_deeply(
    scalar($cache->GetLoadedObjects()),
    {
      'a' => 'alma',
      'b' => 'barack',
      'c' => 'citrom',
      'd' => 'datolya',
      'e' => 'egres'
    },
    'GetLoadedObjects scalar ctx');

$cache->Clear();
is_deeply([$cache->GetLoadedKeys()], [], 'Clear');

# ---- Loader -----------------------------------------------------------------

$seq = 0;
$cache->SetConfig(':loader' =>
    sub
    {
      my ($c, $k, @d) = @_;
      my $v = @d ? $d[0] : $k;
      $c->Add($k => $v);
      ++$seq;
      return $v;
    });

is_deeply([$cache->Get('a')], ['a'], 'loader a add');
is($seq, 1, 'loader a add seq');
is_deeply([$cache->Get('a')], ['a'], 'loader a nop');
is($seq, 1, 'loader a nop seq');

is_deeply([$cache->Get('b', 'c')], ['c'], 'loader b default');
is($seq, 2, 'loader b default seq');
is_deeply([$cache->Get('b')], ['c'], 'loader b get');
is($seq, 2, 'loader b get seq');

# TODO Meta
# TODO Config

# =============================================================================

done_testing();
