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
  my ($self, $keys, @defaults) = @_;

  carp "Too many defaults"
    if (@{$keys} < @defaults);

  my %add;
  @add{@{$keys}} = @defaults;
  $self->Add(\%add);

  return @defaults;
}

sub _Miss
{
  my $loader = $_[0]->{$kConfig}->{$ckLoader};
  return $loader->(@_) if (ref($loader) eq 'CODE');

  my ($self, $keys, @rest) = @_;
  return unless @rest;
  return $self->_MissHandler($keys, @rest)
    unless (ref($rest[0]) eq 'CODE');

  $loader = shift(@rest);
  return $loader->($self, $keys, @rest);
}

sub Get
{
  my ($self, $key, @rest) = @_;
  my @ret;

  croak "Can't use undef as cache key"
    unless defined($key);
  croak "Can't use a " . ref($key) . " reference as a cache key"
    if ref($key);

  my $objects = $self->{$kObjects};
  if (exists($objects->{$key}))
  {
    $ret[0] = $objects->{$key};
  }
  else
  {
    @ret = $self->_Miss([$key], @rest);
  }

  return @ret if wantarray;
  return $ret[0];
}

# ---- GetMany ----------------------------------------------------------------

sub GetMany
{
  my ($self, $keys, @rest) = @_;
  my @ret;

  croak "\$keys should be an arrayref"
    unless (ref($keys) eq 'ARRAY');

  if (!$#{$keys})
  {
    @ret = $self->Get($keys->[0], @rest);
  }
  elsif (@{$keys})
  {
    my @miss_keys;
    my $objects = $self->{$kObjects};
    # @misses = grep { !exists($objects->{$_}) } @{$keys};
    foreach (@{$keys})
    {
      croak "Can't use undef as cache key"
        unless defined($_);
      croak "Can't use a " . ref($_) . " reference as a cache key"
        if ref($_);
      push(@miss_keys, $_) unless exists($objects->{$_});
    }

    if (@miss_keys)
    {
      my %misses;
      @misses{@miss_keys} = $self->_Miss([@miss_keys], @rest);

      # Reload in case _MissHandler changed it
      $objects = $self->{$kObjects};

      @ret = map { exists($misses{$_}) ? $misses{$_} : $objects->{$_} }
          @{$keys};
    }
    else
    {
      @ret = @{$objects}{@{$keys}};
    }
  }

  return @ret if wantarray;
  return \@ret;
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

  if (!ref($key))
  {
    croak "Can't use undef as cache key"
      unless defined($key);
    return unless exists($objects->{$key});
    return $objects->{$key};
  }
  elsif (ref($key) eq 'ARRAY')
  {
    foreach (@{$key})
    {
      croak "Can't use undef as cache key"
        unless defined($_);
      croak "Can't use a " . ref($_) . " reference as a cache key"
        if ref($_);
    }
    return @{$objects}{@{$key}} if wantarray;
    return [@{$objects}{@{$key}}];
  }
  else
  {
    croak "Can't use a " . ref($key) . " reference as a cache key";
  }
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
  }
  else
  {
    my $name = shift;
    my $value = shift;

    croak "Can't use undef as a metadata name" unless defined($name);
    croak "SetMetadata('key', 'name' => \$value)" if @_;

    $self->{$kMetadata}->{$key}->{$name} = $value;
  }

  return $self;
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
  }
  else
  {
    my $name = shift;
    my $value = shift;

    croak "Can't use undef as a config name" unless defined($name);
    croak "SetConfig('name' => \$value)" if @_;

    $self->{$kConfig}->{$name} = $value;
  }

  return $self;
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
