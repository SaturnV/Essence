#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Random;

###### IMPORTS ################################################################

use Essence::Strict;

use Scalar::Util qw( blessed );

###### VARS ###################################################################

our $Generator;

###### METHODS ################################################################

sub _generator
{
  my ($self) = @_;
  my $generator;

  if ($self->can('_bytes'))
  {
    $generator = $self;
  }
  else
  {
    $generator = 'Essence::Random::DevUrandom';
    eval "require $generator" or die $@;
  }

  return $generator;
}

sub generator { return $Generator //= shift->_generator(@_) }

# Macros?
foreach my $method (qw( ByteString
                        S8 S16 S32 S64
                        U8 U16 U32 U64 ))
{
  eval <<__EOT__
sub $method
{
  my \$self = shift;
  return \$self->generator()->$method(\@_);
}
__EOT__
}

###############################################################################

1
