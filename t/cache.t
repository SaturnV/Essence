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
           my ($c, $ks, @rest) = @_;
           ++$seq;
           is_deeply($ks, ['f'], 'miss-callback fz keys');
           is_deeply([@rest], ['arg1', 'arg2'], 'miss-callback fz rest');
           $c->Add($ks->[0] => 'z');
           return 'z'
         }, 'arg1', 'arg2')],
    ['z'],
    'miss-callback fz');
is($seq, 3, 'miss-callback fz seq');

is_deeply(
    [$cache->Get('f', sub { ++$seq ; return 'Z' })],
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
      my ($c, $ks, @d) = @_;
      my $v = @d ? $d[0] : $ks->[0];
      $c->Add($ks->[0] => $v);
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

# ---- GetMany ----------------------------------------------------------------

$cache = Essence::Cache->new(
    'a' => 'alma',
    'b' => 'barac');
is_deeply([$cache->Get('a')], ['alma'], 'initialize');
is_deeply(
    [$cache->GetMany(['a', 'b'])],
    ['alma', 'barac'],
    'GetMany all hit');

is_deeply(
    [$cache->GetMany(['a', 'c', 'd'])],
    ['alma', undef, undef],
    'GetMany miss nodef');
is_deeply([$cache->Get('c')], [], 'GetMany miss nodef get');

is_deeply(
    [$cache->GetMany(['a', 'c', 'd'], 'citrom', 'datolya')],
    ['alma', 'citrom', 'datolya'],
    'GetMany miss defaults');
is_deeply([$cache->Get('c')], ['citrom'], 'GetMany miss defaults get');

$seq = 0;
is_deeply(
    [$cache->GetMany(['a', 'u', 'v'],
         sub
         {
           my ($c, $ks, @rest) = @_;
           ++$seq;

           is_deeply($ks, ['u', 'v'], 'GetMany miss cb ks');
           is_deeply([@rest], ['hello'], 'GetMany miss cb rest');

           my %add;
           my @vs = map { uc($_) } @{$ks};
           @add{@{$ks}} = @vs;
           $c->Add(\%add);

           return @vs;
         }, 'hello')],
    ['alma', 'U', 'V'],
    'GetMany miss cb');
is_deeply([$cache->Get('u')], ['U'], 'GetMany miss cb get');
is($seq, 1, 'GetMany miss cb seq');

$cache->SetConfig(':loader' =>
    sub
    {
      my ($c, $ks, @rest) = @_;
      ++$seq;

      is_deeply($ks, ['p', 'q'], 'GetMany miss loader ks');
      is_deeply([@rest], ['szia'], 'GetMany miss loader rest');

      my %add;
      my @vs = map { uc($_) } @{$ks};
      @add{@{$ks}} = @vs;
      $c->Add(\%add);

      return @vs;
    });

is_deeply(
    [$cache->GetMany(['a', 'p', 'q'], 'szia')],
    ['alma', 'P', 'Q'],
    'GetMany miss loader');
is_deeply([$cache->Get('p')], ['P'], 'GetMany miss loader get');
is($seq, 2, 'GetMany miss loader seq');

# =============================================================================

done_testing();
