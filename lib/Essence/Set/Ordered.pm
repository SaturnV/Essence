#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Set::Ordered;

###### IMPORTS ################################################################

use Essence::Strict;

use List::MoreUtils qw( any none );

###### SUBS ###################################################################

# No need to handle undef
# my $x = [] ; my $y = "$x" ; $x eq $y
sub __eq { return (($_[0] eq $_[1]) && (ref($_[0]) eq ref($_[1]))) }

###### METHODS ################################################################

sub new
{
  # my $class = shift;
  my $self = bless({ '@elems' => [], '%elems' => {}, 'undef' => 0 }, shift);
  return $self->Add(@_);
}

sub Elems { return @{$_[0]->{'@elems'}} }
sub ElemsRef { return $_[0]->{'@elems'} }

sub Contains
{
  my ($self, $e) = @_;
  return defined($e) ?
      ($self->{'%elems'}->{$e} &&
       (any { __eq($e, $_) } @{$self->{'%elems'}->{$e}})) :
      $self->{'undef'};
}

sub Add
{
  my $self = shift;

  my $elems = $self->{'%elems'};
  foreach my $e (@_)
  {
    if (defined($e))
    {
      if ($elems->{$e})
      {
        if (none { __eq($e, $_) } @{$elems->{$e}})
        {
          push(@{$self->{'@elems'}}, $e);
          push(@{$elems->{$e}}, $e);
        }
      }
      else
      {
        push(@{$self->{'@elems'}}, $e);
        $elems->{$e} = [$e];
      }
    }
    elsif (!$self->{'undef'})
    {
      push(@{$self->{'@elems'}}, $e);
      $self->{'undef'} = 1;
    }
  }

  return $self;
}

# TODO Index
# TODO Remove

###############################################################################

1
