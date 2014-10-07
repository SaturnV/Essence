#! /usr/bin/perl

package Essence::FileOps;

use Essence::Strict;

use Exporter qw( import );
use Carp;

our @EXPORT_OK = qw(
    slurp_bytes slurp_utf8
    read_first_line read_1st_line read_first_line_chomp read_1st_line_chomp
    write_bytes write_utf8 );

sub _readline
{
  my $fn = shift;
  my ($ret, $fh);

  if (open($fh, '<', $fn))
  {
    if (@_)
    {
      if (defined($_[0]))
      {
        binmode($fh, $_[0]);
      }
      else
      {
        binmode($fh);
      }
    }

    $ret = readline($fh);
    croak "read('$fn'): $!"
      unless (defined($ret) || eof($fh));
    close($fh) or
      croak "close('$fn'): $!";
  }
  elsif (!$!{'ENOENT'})
  {
    croak "open('$fn', r): $!";
  }

  return $ret;
}

sub slurp_bytes
{
  local $/;
  return _readline($_[0], undef);
}

sub slurp_utf8
{
  local $/;
  return _readline($_[0], ':utf8');
}

sub read_first_line { return _readline($_[0], ':utf8') }
sub read_1st_line { return _readline($_[0], ':utf8') }
sub read_first_line_chomp
{
  my $l = read_first_line(@_);
  chomp($l) if defined($l);
  return $l;
}
sub read_1st_line_chomp { return read_first_line_chomp(@_) }

sub _print
{
  my ($fn, $content) = (shift, shift);
  my ($ret, $fh);

  if (open($fh, '>', $fn))
  {
    if (@_)
    {
      if (defined($_[0]))
      {
        binmode($fh, $_[0]);
      }
      else
      {
        binmode($fh);
      }
    }

    print $fh $content or
      croak "write('$fn'): $!"
      unless ($content eq '');
    close($fh) or
      croak "close('$fn'): $!";
  }
  else
  {
    croak "open('$fn', w): $!";
  }

  return length($content);
}

sub write_bytes { return _print($_[0], $_[1], undef) }
sub write_utf8 { return _print($_[0], $_[1], ':utf8') }

1
