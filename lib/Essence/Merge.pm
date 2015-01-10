#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Merge;

###### IMPORTS ################################################################

use Essence::Strict;

use Essence::Set::Ordered;
use Carp;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw( merge_arrays merge_arrays_keep_order merge_hashes merge
                     merge_deep_default merge_deep_override );

###### SUBS ###################################################################

# ---- shallow ----------------------------------------------------------------

# No need to handle undef
sub __eq { return (($_[0] eq $_[1]) && (ref($_[0]) eq ref($_[1]))) }

# [c] + [a b c] => [c a b]
sub merge_arrays
{
  my $merged = Essence::Set::Ordered->new();

  foreach my $arr (@_)
  {
    croak "merge_arrays() arguments should be ARRAY references"
      unless (ref($arr) eq 'ARRAY');
    $merged->Add(@{$arr});
  }

  return $merged->ElemsRef();
}

# [c] + [a b c] => [a b c]
sub merge_arrays_keep_order
{
  my $merged = Essence::Set::Ordered->new();

  my ($left, $right, @left, @right);
  foreach my $arr (@_)
  {
    croak "merge_arrays_keep_order() arguments should be ARRAY references"
      unless (ref($arr) eq 'ARRAY');

    @left = $merged->Elems();
    $left = $merged;

    @right = @{$arr};
    $right = Essence::Set::Ordered->new(@right);

    $merged = Essence::Set::Ordered->new();

    while (@left && @right)
    {
      if ($right->Contains($left[0]))
      {
        $merged->Add($right[0])
          unless $left->Contains($right[0]);
        shift(@right);
      }
      else
      {
        $merged->Add(shift(@left));
      }
    }
    $merged->Add(@left, @right);
  }

  return $merged->ElemsRef();
}

sub merge_hashes
{
  my $ret = {};

  foreach my $h (@_)
  {
    croak "merge_hashes() arguments should be HASH references"
      unless (ref($h) eq 'HASH');

    foreach (keys(%{$h}))
    {
      $ret->{$_} = $h->{$_}
        unless exists($ret->{$_});
    }
  }

  return $ret;
}

sub merge
{
  return (ref($_[0]) eq 'ARRAY') ?
      merge_arrays(@_) :
      merge_hashes(@_);
}

# ---- deep / default ---------------------------------------------------------

# right value used if left value is missing
sub merge_deep_default
{
  my $ret = {};

  foreach my $h (@_)
  {
    croak "merge_deep_default() arguments should be HASH references"
      unless (ref($h) eq 'HASH');

    foreach (keys(%{$h}))
    {
      if (exists($ret->{$_}))
      {
        if ((ref($ret->{$_}) eq 'ARRAY') && (ref($h->{$_}) eq 'ARRAY'))
        {
          $ret->{$_} = merge_arrays($ret->{$_}, $h->{$_});
        }
        elsif ((ref($ret->{$_}) eq 'HASH') && (ref($h->{$_}) eq 'HASH'))
        {
          $ret->{$_} = merge_deep_default($ret->{$_}, $h->{$_});
        }
        # Keep original value otherwise
      }
      else
      {
        $ret->{$_} = $h->{$_};
      }
    }
  }

  return $ret;
}

# ---- deep / override --------------------------------------------------------

# right value overrides left
sub merge_deep_override
{
  my $ret = {};

  foreach my $h (@_)
  {
    croak "merge_deep_override() arguments should be HASH references"
      unless (ref($h) eq 'HASH');

    foreach (keys(%{$h}))
    {
      if (exists($ret->{$_}))
      {
        if ((ref($ret->{$_}) eq 'ARRAY') && (ref($h->{$_}) eq 'ARRAY'))
        {
          $ret->{$_} = merge_arrays($ret->{$_}, $h->{$_});
        }
        elsif ((ref($ret->{$_}) eq 'HASH') && (ref($h->{$_}) eq 'HASH'))
        {
          $ret->{$_} = merge_deep_override($ret->{$_}, $_[1]);
        }
        else
        {
          $ret->{$_} = $h->{$_};
        }
      }
      else
      {
        $ret->{$_} = $h->{$_};
      }
    }
  }

  return $ret;
}

###############################################################################

1
