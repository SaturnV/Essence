#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Utils;

###### IMPORTS ################################################################

use Essence::Strict;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT_OK = qw( normalize_str camelcase
    quote_html unquote_html remove_html
    pick picks );

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

sub camelcase
{
  my $str = $_[0];
  my $prefix = ($str =~ s/^(_*)//) ? $1 : '';
  $str =~ s/_([a-z])/uc($1)/eg;
  return $prefix . ucfirst($str);
}

sub quote_html
{
  my $txt = $_[0];
  $txt =~ s/&/&amp;/g;
  $txt =~ s/</&lt;/g;
  $txt =~ s/>/&gt;/g;
  $txt =~ s/"/&quot;/g;
  return $txt;
}

sub unquote_html
{
  my $txt = $_[0];
  $txt =~ s/&lt;/</g;
  $txt =~ s/&gt;/>/g;
  $txt =~ s/&quot;/"/g;
  $txt =~ s/&nbsp;/ /g;
  $txt =~ s/&amp;/&/g;
  return $txt;
}

sub remove_html
{
  my $txt = $_[0];
  $txt =~ s/(?:<[^>]+>)+/ /g;
  return unquote_html($txt);
}

sub pick
{
  my $from = shift;
  return map { exists($from->{$_}) ? ($_ => $from->{$_}) : () } @_
    if wantarray;
  return { map { exists($from->{$_}) ? ($_ => $from->{$_}) : () } @_ };
}
sub picks { return scalar(pick(@_)) }

###############################################################################

1
