#! /usr/bin/perl
# TODO Transaction primitives (begin_work, commit, rollback)?

package Essence::Sql::AsyncMysql;

use Essence::Strict;

use parent 'Essence::Sql';

use AnyEvent;

sub _db_op
{
  # my ($self, $handle, $op, @params) = @_;

  given ($_[2])
  {
    when ('prepare')
    {
      my ($self, $handle, $op, $sql, $opts, @rest) = @_;
      $opts //= {};
      $opts->{'async'} //= 1;
      return $self->next::method($handle, $op, $sql, $opts, @rest);
    }
    when ('execute')
    {
      # my ($self, $handle, $op, @params) = @_;
      my ($self, $handle) = @_;
      return $self->_AsyncWait($handle, shift->next::method(@_));
    }
    when ('do')
    {
      # my ($self, $handle, $op, $sql, $opts, @params) = @_;
      if (!$_[4] || !defined($_[4]->{'async'}) || $_[4]->{'async'})
      {
        my ($self, $handle, $op, $sql, $opts, @params) = @_;
        $opts //= {};
        $opts->{'async'} //= 1;
        return $self->_AsyncWait(
            $handle,
            $self->next::method($handle, $op, $sql, $opts, @params));
      }
    }
    when ('selectall_arrayref')
    {
      # my ($self, $handle, $op, $sql, $opts, @params) = @_;
      if (!$_[4] || !defined($_[4]->{'async'}) || $_[4]->{'async'})
      {
        my ($self, $handle, $op, $sql, $opts, @params) = @_;
        my $sth = $self->_db_op($handle, 'prepare', $sql, $opts) or return;
        $self->_db_op($sth, 'execute', @params) or return;
        return $self->_db_op($sth, 'fetchall_arrayref');
      }
    }
  }

  return shift->next::method(@_);
}

sub _AsyncWait
{
  my ($self, $handle, $ret) = @_;

  my $rdy;
  while (defined($rdy = $handle->mysql_async_ready()) && !$rdy)
  {
    my $cv = AnyEvent->condvar();
    my $io = AnyEvent->io(
        'fh' => $self->dbh()->mysql_fd(),
        'poll' => 'r',
        'cb' => sub { $cv->send() });
    # $self->LogDebug('BLOCK');
    $cv->recv();
    # $self->LogDebug('UNBLOCK');
  }
  $ret = $handle->mysql_async_result()
    if defined($rdy);

  return $ret;
}

1
