#! /usr/bin/perl
###### NAMESPACE ##############################################################

package Essence::Logger::Mixin;

###### IMPORTS ################################################################

use Essence::Strict;

use Essence::Logger qw();

use Carp;

###### METHODS ################################################################

sub log_prefix { return ref($_[0]) || $_[0] }

sub fmt_error_msg
{
  my $prefix = shift->log_prefix();
  return "$prefix: @_";
}

sub fmt_error_msg_nl
{
  my $msg = shift->fmt_error_msg(@_);
  if (defined($msg) && !ref($msg))
  {
    chomp($msg);
    $msg .= "\n";
  }
  return $msg;
}

sub Log
{
  my ($self, $level, $first, @rest) = @_;
  return Essence::Logger->Log($level,
      $self->fmt_error_msg($first),
      @rest);
}

sub LogDebug { return shift->Log('debug', @_) };
sub LogInfo { return shift->Log('info', @_) };
sub LogWarn { return shift->Log('warn', @_) };
sub LogWarning { return shift->Log('warn', @_) };
sub LogError { return shift->Log('error', @_) };
sub LogFatal { return shift->Log('fatal', @_) };

sub Die { die shift->fmt_error_msg_nl(@_) }
sub Warn { warn shift->fmt_error_msg_nl(@_) }
sub Carp { carp shift->fmt_error_msg(@_) }
sub Cluck { Carp::cluck shift->fmt_error_msg(@_) }
sub Croak { croak shift->fmt_error_msg(@_) }
sub Confess { confess shift->fmt_error_msg(@_) }

###############################################################################

1
