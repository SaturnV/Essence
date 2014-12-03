#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Random::Generator;

###### IMPORTS ################################################################

use Essence::Strict;

use Carp;

###### VARS ###################################################################

my $mod_name = __PACKAGE__;

###### METHODS ################################################################

# Implement this in your generator
sub _GetBytes { die }

# ==== Public interface =======================================================

# Optional
# $rng = $class->new();
# $rng = $class->new($seed);
# $rng->Reset();
# $rng->Reset($seed);
# $state = $rng->Save();
# $rng->Restore($state);

sub ByteString
{
  # my ($self, $length) = @_;
  # $length = $self->_check_length($length);
  # return $self->_GetBytes($length);
  my $self = shift;
  return $self->_GetBytes($self->_check_length(@_));
}

# ---- Uniform distribution ---------------------------------------------------

# TODO Integer
# TODO Float

sub S8 { return shift->_Unpack('c', 1, @_) }
sub U8 { return shift->_Unpack('C', 1, @_) }
sub S16 { return shift->_Unpack('s', 2, @_) }
sub U16 { return shift->_Unpack('S', 2, @_) }
sub S32 { return shift->_Unpack('l', 4, @_) }
sub U32 { return shift->_Unpack('L', 4, @_) }
sub S64 { return shift->_Unpack('q', 8, @_) }
sub U64 { return shift->_Unpack('Q', 8, @_) }

# ==== Implementation =========================================================

sub _check_length
{
  my ($self, $length) = @_;

  croak "No length" unless defined($length);
  croak "That doesn't look like a valid length"
    unless ($length =~ /^\d+\z/);

  return $length;
}

sub _check_n
{
  my ($self, $n, $wantarray) = @_;
  $n //= 1;

  croak "That doesn't look like a valid number"
    unless ($n =~ /^\d+\z/);

  if (!$wantarray)
  {
    if ($n > 1)
    {
      croak "Multiple objects requested but not in list context";
    }
    elsif ($n < 1)
    {
      croak "Can only produce one object in scalar context";
    }
  }

  return $n;
}

sub _Unpack
{
  my ($self, $type, $sizeof, $n) = @_;
  my @ret;

  $n = $self->_check_n($n, wantarray);
  @ret = unpack($type x $n, $self->_GetBytes($sizeof * $n));

  return @ret if wantarray;
  return $ret[0];
}

###############################################################################

1
