#! /usr/bin/perl

package Essence::Module;

use Essence::Strict;

use Exporter qw( import );

our @EXPORT_OK = qw( module2class module2fn load_module );

sub module2class { return join('::', map { ref($_) || $_ } @_) }
sub module2fn
{
  my $fn = module2class(@_);
  $fn =~ s{::}{/}g;
  return "$fn.pm";
}

sub load_module
{
  my $class = module2class(@_);
  my $fn = module2fn(@_);
  require $fn;
  return $class;
}

1
