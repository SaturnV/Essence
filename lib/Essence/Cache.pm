#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Cache;

###### IMPORTS ################################################################

use Essence::Strict;
use Carp;

###### VARS ###################################################################

our $kObjects = 'objects';
our $kConfig = 'config';
our $kMetadata = 'metadata';

our $ckLoader = ':loader';

###### METHODS ################################################################

# ==== Objects ================================================================

# ---- Remove / Clear ---------------------------------------------------------

sub Remove
{
  my $self = shift;

  my $objects = $self->{$kObjects};
  my $metadata = $self->{$kMetadata};
  foreach (@_)
  {
    delete($objects->{$_});
    delete($metadata->{$_});
  }

  return $self;
}

sub Clear
{
  my $self = $_[0];
  %{$self->{$kObjects}} = ();
  %{$self->{$kMetadata}} = ();
  return $self;
}

# ---- Add / AddWeak / Replace ------------------------------------------------

sub _Replace
{
  my ($self, $key, $value) = @_;
  $self->{$kObjects}->{$key} = $value;
  return $self;
}

sub _Add
{
  my ($self, $key, @value) = @_;
  delete($self->{$kMetadata}->{$key});
  return $self->_Replace($key, @value);
}

sub _AddWeak
{
  my ($self, $key, @rest) = @_;
  return if exists($self->{$kObjects}->{$key});
  return $self->_Add($key, @rest);
}

sub _AddDriver
{
  my $self = shift;
  my $adder = shift;

  while (@_)
  {
    croak "Can't use undef as cache key"
      unless defined($_[0]);

    given (ref($_[0]))
    {
      when ('') { $self->$adder($_[0] => $_[1]) ; shift ; shift }
      when ('ARRAY') { $self->_AddDriver($adder, @{shift()}) }
      when ('HASH')
      {
        my $h = shift;
        $self->$adder($_ => $h->{$_})
          foreach (keys(%{$h}));
      }
      default { croak "Can't use " . ref($_[0]) . " as cache key" }
    }
  }

  return $self;
}

# Add / replace object, ignoring metadata
sub Replace
{
  my $self = shift;
  return $self->_AddDriver($self->can('_Replace'), @_);
}

# Add / replace object, clear metadata for key
sub Add
{
  my $self = shift;
  return $self->_AddDriver($self->can('_Add'), @_);
}

# Like Add but nop if already loaded
sub AddWeak
{
  my $self = shift;
  return $self->_AddDriver($self->can('_AddWeak'), @_);
}

# ---- Get / _Miss ------------------------------------------------------------

sub _MissHandler
{
  my ($self, $key, $default, @rest) = @_;

  if (ref($default) eq 'CODE')
  {
    return $default->($self, $key, @rest);
  }
  else
  {
    $self->Add($key => $default, @rest);
    return ($default);
  }
}

sub _Miss
{
  my ($self, $key, @default) = @_;
  return $self->_MissHandler($key, $self->{$kConfig}->{$ckLoader}, @default)
    if exists($self->{$kConfig}->{$ckLoader});
  return $self->_MissHandler($key, @default)
    if @default;
  return;
}

sub Get
{
  my ($self, $key, @default) = @_;
  my @ret;

  my $objects = $self->{$kObjects};
  if (exists($objects->{$key}))
  {
    $ret[0] = $objects->{$key};
  }
  else
  {
    @ret = $self->_Miss($key, @default);
  }

  return @ret if wantarray;
  return $ret[0];
}

# ---- Misc readers -----------------------------------------------------------

sub IsLoaded
{
  my ($self, $key) = @_;
  return exists($self->{$kObjects}->{$key});
}

sub GetIfLoaded
{
  my ($self, $key) = @_;
  my $objects = $self->{$kObjects};
  return unless exists($objects->{$key});
  return $objects->{$key};
}

sub GetLoadedKeys { return keys(%{$_[0]->{$kObjects}}) }

sub GetLoadedObjects
{
  return values(%{$_[0]->{$kObjects}}) if wantarray;
  return { %{$_[0]->{$kObjects}} };
}

# ==== Metadata ===============================================================

sub GetMetadata
{
  my $self = shift;
  my $key = shift;

  croak "Can't use undef as cache key" unless defined($key);

  my $metadata = $self->{$kMetadata}->{$key};

  return $metadata //= $self->{$kMetadata}->{$key} = {}
    unless @_;

  my $name = shift;
  croak "Can't use undef as a metadata name" unless defined($name);
  croak "GetMetadata('key', 'name')" if @_;

  return unless ($metadata && exists($metadata->{$name}));
  return $metadata->{$name};
}

sub SetMetadata
{
  my $self = shift;
  my $key = shift;

  croak "Can't use undef as cache key" unless defined($key);

  if (ref($_[0]) eq 'HASH')
  {
    croak "SetMetadata('key' => \$metadata_hashref)" if $#_;
    $self->{$kMetadata}->{$key} = $_[0];
    return $self;
  }
  else
  {
    my $name = shift;
    my $value = shift;

    croak "Can't use undef as a metadata name" unless defined($name);
    croak "SetMetadata('key', 'name' => \$value)" if @_;

    return $self->{$kMetadata}->{$key}->{$name} = $value;
  }
}

sub RemoveMetadata
{
  my $self = shift;
  my $key = shift;

  croak "Can't use undef as cache key" unless defined($key);

  if (my $metadata = $self->{$kMetadata}->{$key})
  {
    delete($metadata->{$_}) foreach (@_);
  }

  return $self;
}

sub ClearMetadata
{
  my ($self, $key) = @_;

  croak "Can't use undef as cache key" unless defined($key);

  if (my $metadata = $self->{$kMetadata}->{$key})
  {
    %{$metadata} = ();
  }

  return $self;
}

sub ClearAllMetadata
{
  my $self = $_[0];
  %{$self->{$kMetadata}} = ();
  return $self;
}

# ==== Config =================================================================

sub GetConfig
{
  my $self = shift;

  if (@_)
  {
    my $name = shift;

    croak "Can't use undef as a config name" unless defined($name);
    croak "GetConfig('name')" if @_;

    my $config = $self->{$kConfig};
    return unless exists($config->{$name});
    return $config->{$name};
  }
  else
  {
    return $self->{$kConfig};
  }
}

sub SetConfig
{
  my $self = shift;

  if (ref($_[0]) eq 'HASH')
  {
    croak "SetConfig(\$config_hashref)" if $#_;
    $self->{$kConfig} = $_[0];
    return $self;
  }
  else
  {
    my $name = shift;
    my $value = shift;

    croak "Can't use undef as a config name" unless defined($name);
    croak "SetConfig('name' => \$value)" if @_;

    return $self->{$kConfig}->{$name} = $value;
  }
}

sub RemoveConfig
{
  my $self = shift;
  my $config = $self->{$kConfig};
  delete($config->{$_}) foreach (@_);
  return $self;
}

sub ClearConfig
{
  my $self = $_[0];
  %{$self->{$kConfig}} = ();
  return $self;
}

# ==== Class methods ==========================================================

sub new
{
  my $class = shift;
  my $self = bless(
      {
        $kConfig => {},
        $kObjects => {},
        $kMetadata => {},
      }, $class);
  return @_ ? $self->Add(@_) : $self;
}

###############################################################################

1
