#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Merge;

###### IMPORTS ################################################################

use Essence::Strict;

use List::MoreUtils qw( none );
use Carp;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw( merge_arrays merge_hashes merge
                     merge_deep_default merge_deep_override );

###### SUBS ###################################################################

# ---- shallow ----------------------------------------------------------------

# No need to handle undef
sub __eq { return (($_[0] eq $_[1]) && (ref($_[0]) eq ref($_[1]))) }

sub merge_arrays
{
  my @ret;

  my (%elems, $undef, $str);
  foreach my $arr (@_)
  {
    croak "merge_arrays() arguments should be ARRAY references"
      unless (ref($arr) eq 'ARRAY');

    foreach my $elem (@{$arr})
    {
      if (defined($elem))
      {
        if ($elems{$elem})
        {
          # my $x = [] ; my $y = "$x" ; $x eq $y
          if (none { __eq($elem, $_) } @{$elems{$elem}})
          {
            push(@{$elems{$elem}}, $elem);
            push(@ret, $elem);
          }
        }
        else
        {
          $elems{$elem} = [$elem];
          push(@ret, $elem);
        }
      }
      elsif (!$undef)
      {
        push(@ret, $elem);
        $undef = 1;
      }
    }
  }

  return \@ret;
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
