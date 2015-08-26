#! /usr/bin/perl
###### NAMESAPCE ##############################################################

package Essence::Stats;

###### IMPORTS ################################################################

use Essence::Strict;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw(
  count count_ref
  sum sum_ref sum_count sum_count_ref
  avg avg_ref avg_count avg_count_ref
  dev2_avg_count dev2_avg_count_ref dev2 dev2_ref
  pbs );

###### VARS ###################################################################

our $Epsilon = 1e-12;

###### SUBS ###################################################################

# ==== Simple =================================================================

# ---- count / sum ------------------------------------------------------------

sub count { return scalar(@_) }

sub count_ref
{
  my $n = 0;
  $n += @{$_} foreach @_;
  return $n;
}

sub sum
{
  my $sum = 0;
  $sum += $_ foreach @_;
  return $sum;
}

sub sum_ref
{
  my $sum = 0;
  foreach my $ref (@_)
  {
    $sum += $_ foreach @{$ref};
  }
  return $sum;
}

sub sum_count { return (sum(@_), scalar(@_)) }

sub sum_count_ref
{
  my $n = 0;
  my $sum = 0;
  foreach my $ref (@_)
  {
    $sum += $_ foreach @{$ref};
    $n += @{$ref};
  }
  return ($sum, $n);
}

# ---- avg / dev --------------------------------------------------------------

sub avg { return @_ ? sum(@_) / @_ : undef }

sub avg_ref
{
  my ($sum, $n) = sum_count_ref(@_);
  return $n ? $sum / $n : undef;
}

sub avg_count { return @_ ? (sum(@_) / @_, scalar(@_)) : (undef, 0) }

sub avg_count_ref
{
  my ($sum, $n) = sum_count_ref(@_);
  return $n ? ($sum / $n, $n) : (undef, $n);
}

sub dev2_avg_count
{
  return (undef, undef, 0) unless @_;

  my $sum = 0;
  my $sqr = 0;
  foreach (@_)
  {
    $sqr += $_ * $_;
    $sum += $_;
  }

  return ($sqr / @_ - ($sum / @_) ** 2, $sum / @_, scalar(@_));
}

sub dev2_avg_count_ref
{
  my $n = 0;
  my $sum = 0;
  my $sqr = 0;
  foreach my $ref (@_)
  {
    foreach (@{$ref})
    {
      $sqr += $_ * $_;
      $sum += $_;
    }
    $n += @{$ref};
  }
  return $n ?
      ($sqr / $n - ($sum / $n) ** 2, $sum / $n, $n) :
      (undef, undef, 0);
}

sub dev2 { return (dev2_avg_count(@_))[0] }
sub dev2_ref { return (dev2_avg_count_ref(@_))[0] }

# ==== Advanced ===============================================================

sub pbs
{
  my ($good, $bad) = @_;

  my ($good_avg, $good_n) = avg_count_ref($good);
  my ($bad_avg, $bad_n) = avg_count_ref($bad);
  return undef unless ($good_n || $bad_n);
  return 0 unless ($good_n && $bad_n);

  my $dev2 = dev2_ref($good, $bad);

  return ($dev2 >= $Epsilon) ?
      (($good_avg - $bad_avg) / sqrt($dev2)) *
          sqrt(($good_n * $bad_n) / ($good_n + $bad_n) ** 2) :
      0;
}

###############################################################################

1
