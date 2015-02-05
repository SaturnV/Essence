#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Utils;

###### IMPORTS ################################################################

use Essence::Strict;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw( normalize_str pick picks );

###### SUBS ###################################################################

sub normalize_str
{
  my $str = $_[0];

  if (defined($str))
  {
    $str =~ s/\s+\z//;
    $str =~ s/^\s+//;
    $str =~ s/\s+/ /g;
  }

  return $str;
}

sub pick
{
  my $from = shift;
  return map { ($_ => $from->{$_}) } @_ if wantarray;
  return { map { ($_ => $from->{$_}) } @_ };
}
sub picks { return scalar(pick(@_)) }

###############################################################################

1
