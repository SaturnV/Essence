#! /usr/bin/perl

package Essence::Logger::Id;

use Essence::Strict;

use parent 'Essence::Logger';

# There is no Essence::Logger->new()
sub new
{
  my ($class, $id) = @_;
  return bless({ 'id' => $id }, $class);
}

sub generate_id
{
  state $seq = 0;
  return '<anon:' . $seq++ . '>';
}

sub Id
{
  my $self = shift;
  $self->{'id'} = $_[0] if @_;
  return $self->{'id'};
}

sub Header
{
  # my ($self, $level) = @_;
  my $self = shift;
  my $hdr = $self->next::method(@_);
  my $id = $self->Id();
  $hdr =~ s/\K(?=:\s+\z)/ $id/
    if defined($id);
  return $hdr;
}

1
