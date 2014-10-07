#! /usr/bin/perl
# TODO Logging to file
# TODO Reopen log
# TODO Don't log messages below a threshold
###### NAMESPACE ##############################################################

package Essence::Logger;

###### IMPORTS ################################################################

use Essence::Strict;

use Scalar::Util qw( blessed );
use Data::Dumper;

use Essence::Time;

###### EXPORTS ################################################################

use Exporter qw( import );

our @EXPORT =
    qw( log_debug log_info log_warn log_warning log_error log_fatal );

###### VARS ###################################################################

my $mod_name = __PACKAGE__;

# Defaults
# our $Default = __PACKAGE__;
# our $InstallHandlers = 1;

###### METHODS ################################################################

sub _default_logger { $Essence::Logger::Default // $_[0] // __PACKAGE__ }

# ==== Formatting =============================================================

sub MsgSeparator { return "\n" }

sub FormatDate
{
  # my ($self, $time_sec, $time_usec) = @_;
  shift;
  return Essence::Time::fmt_localtime_us(@_);
}

sub FormatDump
{
  my $self = shift;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Pad = '    ';
  my $dump = Data::Dumper::Dumper(@_);
  chomp($dump);
  return $dump;
}

sub FormatMsg
{
  my $self = shift;

  if (ref($_[0]))
  {
    return $_[0]->to_string()
      if (blessed($_[0]) && $_[0]->can('to_string'));
    return $self->FormatDump(@_);
  }
  else
  {
    return (defined($_[0]) ? $_[0] : '<undef>');
  }
}

sub Format
{
  my $self = shift;
  my $msg = $self->Header(shift) .
      join($self->MsgSeparator() // $, // '',
          map { $self->FormatMsg($_) } @_);
  $msg .= "\n" unless (substr($msg, -1, 1) eq "\n");
  return $msg;
}

sub Header
{
  # my ($self, $level) = @_;
  return sprintf('%s %7s: ', $_[0]->FormatDate(), "[$_[1]]");
}

sub WriteToLog
{
  # my ($self, $msg) = @_;
  my $written = syswrite(STDERR, $_[1]);
  die "$mod_name: write: $!\n"
    unless defined($written);
  die "$mod_name: write: Short write\n"
    unless ($written == length($_[1]));
  return $_[1];
}

sub Log
{
  my $self = shift;
  $self = $self->_default_logger() unless ref($self);
  return $self->WriteToLog($self->Format(@_));
}

sub LogDebug { return shift->Log('debug', @_) }
sub LogInfo { return shift->Log('info', @_) }
sub LogWarn { return shift->Log('warn', @_) }
sub LogWarning { return shift->Log('warn', @_) }
sub LogError { return shift->Log('error', @_) }
sub LogFatal { return shift->Log('fatal', @_) }

###### SUBS ###################################################################

sub _log { return _default_logger()->Log(@_) }

sub log_debug { return _log('debug', @_) }
sub log_info { return _log('info', @_) }
sub log_warn { return _log('warn', @_) }
sub log_warning { return _log('warn', @_) }
sub log_error { return _log('error', @_) }
sub log_fatal { return _log('fatal', @_) }

###### HANDLERS ###############################################################

sub __warn__ { log_warn(@_) }
sub __die__
{
  if (defined($^S))
  {
    die $_[0] if $^S;
    log_fatal($_[0]);
    exit(1);
  }
}

sub install_handlers
{
  $SIG{'__WARN__'} = \&__warn__;
  $SIG{'__DIE__'} = \&__die__;
}

install_handlers() if ($Essence::Logger::InstallHandlers // 1);

###############################################################################

1
