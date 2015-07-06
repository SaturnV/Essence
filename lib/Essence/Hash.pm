#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Hash;

###### IMPORTS ################################################################

use Essence::Strict;

use Carp;

###### EXPORTS ################################################################

use Exporter qw( import );
our @EXPORT_OK = qw( all_keys common_keys );

###### SUBS ###################################################################

sub all_keys
{
  my %keys;

  eval
  {
    foreach my $h (@_)
    {
      $keys{$_} = 1 foreach (keys(%{$h}))
    }
  };
  croak "Arguments to all_keys should be hash references" if $@;

  return keys(%keys);
}

sub common_keys
{
  my @keys;

  if (@_)
  {
    eval
    {
      @keys = keys(%{shift(@_)});

      foreach my $h (@_)
      {
        @keys = grep { exists($h->{$_}) } @keys;
      }
    };
    croak "Arguments to common_keys should be hash references" if $@;
  }

  return @keys;
}

###############################################################################

1
