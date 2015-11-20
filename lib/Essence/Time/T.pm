#! /usr/bin/perl

package Essence::Time::T;

use Essence::Strict;

use Time::HiRes;

use Exporter qw( import );

our @EXPORT_OK = qw( t_now );

my $mod_name = __PACKAGE__;

my $u = 1e6;

sub _fix
{
  my ($s, $us) = @_;

  if ($us < 0)
  {
    my $fix = int(-$us / $u + 1.0);
    $us += $fix * $u;
    $s -= $fix;
  }
  elsif ($us >= $u)
  {
    $s += int($us / $u);
    $us %= $u;
  }

  return ($s, $us);
}

sub new
{
  my $t = shift;
  return bless([@_], ref($t) || $t);
}

sub new_fixed
{
  my $t = shift;
  return $t->new(_fix(@_));
}

sub from_s
{
  # my ($t, $s) = @_;
  my $s = int($_[1]);
  my $us = int(($_[1] - $s) * $u);
  return $_[0]->new_fixed($s, $us);
}

sub t_now
{
  my $class = @_ ? $_[0] : $mod_name;
  return $class->new(Time::HiRes::gettimeofday());
}

sub t_add
{
  # my ($t, $t_add);
  return $_[0]->new_fixed(
      $_[0]->[0] + $_[1]->[0],
      $_[0]->[1] + $_[1]->[1]);
}

sub t_add_s
{
  # my ($t, $add_s) = @_;
  my $t = shift;
  return $t->t_add($t->from_s(@_));
}

sub t_cmp
{
  # my ($t_a, $t_b) = @_;
  return ($_[0]->[0] <=> $_[1]->[0]) || ($_[0]->[1] <=> $_[1]->[1]);
}
sub t_lt { return (t_cmp(@_) < 0) }
sub t_le { return (t_cmp(@_) <= 0) }
sub t_eq { return (t_cmp(@_) == 0) }
sub t_ne { return (t_cmp(@_) != 0) }
sub t_ge { return (t_cmp(@_) >= 0) }
sub t_gt { return (t_cmp(@_) > 0) }

sub t_cmp_s
{
  # my ($t_a, $s_b) = @_;
  my $t = shift;
  return $t->t_cmp($t->from_s(@_));
}
sub t_lt_s { return (t_cmp_s(@_) < 0) }
sub t_le_s { return (t_cmp_s(@_) <= 0) }
sub t_eq_s { return (t_cmp_s(@_) == 0) }
sub t_ne_s { return (t_cmp_s(@_) != 0) }
sub t_ge_s { return (t_cmp_s(@_) >= 0) }
sub t_gt_s { return (t_cmp_s(@_) > 0) }

1
